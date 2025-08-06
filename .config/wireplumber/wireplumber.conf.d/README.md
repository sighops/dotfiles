# Stereo audio out through a USB mixer using pipewire

## Problem
I have an Allen and Heath Qu-SB mixer, which can be used as a USB audio device.  It's configured to have USB audio sent to input channels 31/32 so that all the physical inputs are free(it only has 16, but expandable to 32).  I want stereo audio from my desktop to play through the monitors connected to the mixer.
The issue, however, is that the stereo audio from apps is automatically mapped to inputs 1 and 2 on my mixer.

The GUI apps I've seen recommended all over do allow you to change the channels and get audio out, but they're honestly overkill, require wiring up each new process, and they don't create a config that persists through a reboot without launching the GUI app again.  

## Solution
This creates a persistent config with no other required apps.
The config change you want to make is actually in wireplumber which sits on top of pipewire, so to speak, and handles the session management and automatic linking of audio streams to your device(s).  The below solution assumes you have wireplumber 0.5.0 or newer.  You can check by running:

    wireplumber --version


The most straightforward way of doing this is to create a new config file in:
    
    ~/.config/wireplumber/wireplumber.conf.d

If that directory doesn't exist you should create it(I'm on Fedora 42 and it did not).  For the config file, I named mine 10-map-stereo-channels.conf

Next we need to get some details for the contents of our config file. Run:

    wpctl status

You should see your output device under the Audio section, either under Sinks or Filters(depending on if it's a pro audio, multichannel, etc.)
My Allen and Heath Qu-SB mixer is set as Pro Audio, so it shows up with the following output:

```
  Audio
 ├─ Devices:
 │      55. GP104 High Definition Audio Controller [alsa]
 │      56. QU-SB                               [alsa]
 │  
 ├─ Sinks:
 │      62. GP104 High Definition Audio Controller Digital Stereo (HDMI) [vol: 0.50]
 │  
 ├─ Sources:
 │  
 ├─ Filters:
 │    - pro-audio-1                                                 
 │  *   80. alsa_output.usb-Allen_Heath_Ltd_QU-SB-01.pro-output-0        [Audio/Sink]
 │  *   95. alsa_input.usb-Allen_Heath_Ltd_QU-SB-01.pro-input-0          [Audio/Source]
```

Take note of the ID to the left.  Mine is 80 so I then run:

    wpctl inspect 80

Take note of the `node.name` and `audio.position` values, as we'll be using them in our config file.  For me, I see:

```
...
audio.position = "AUX0,AUX1,AUX2,AUX3,AUX4,AUX5,AUX6,AUX7,AUX8,AUX9,AUX10,AUX11,AUX12,AUX13,AUX14,AUX15,AUX16,AUX17,AUX18,AUX19,AUX20,AUX21,AUX22,AUX23,AUX24,AUX25,AUX26,AUX27,AUX28,AUX29,AUX30,AUX31"
...
node.name = "alsa_output.usb-Allen_Heath_Ltd_QU-SB-01.pro-output-0"
```

As you can see above, the AUX30 and AUX31 channels correspond to channels 31/32 on my mixer.  What we need to do next is update the properties of this node so that those channels are renamed to FL and FR.  
When wireplumber is creating links between output and input channels, it prefers to link channels with the same name.  Otherwise, it makes a best effort and eventually just falls back to picking the first two channels.  The logic for channel selection can be found here:
https://github.com/PipeWire/wireplumber/blob/15f5f96693d6155750db3713d696eb41446fadbc/modules/module-si-standard-link.c#L333
https://github.com/PipeWire/wireplumber/blob/15f5f96693d6155750db3713d696eb41446fadbc/modules/module-si-standard-link.c#L249

Creating the config file with the below contents renames the mixer channels and causes the correct channels to get linked automatically.  Just change the node name and audio position according to your device's setup. Also, for the node name, you can put only the `node.name` you got before as the string.
I've set mine to match on the pattern below so that the name will match whether the device is configured as Pro Audio, multichannel output, etc.  When changing between those profiles the `node.name` can change which can break this config.  The pattern seen here ensures this doesn't break when switching device profiles.

```
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.usb-Allen_Heath_Ltd_QU-SB-01.*"
      }
    ]
    actions = {
      update-props = {
        audio.position = "AUX0,AUX1,AUX2,AUX3,AUX4,AUX5,AUX6,AUX7,AUX8,AUX9,AUX10,AUX11,AUX12,AUX13,AUX14,AUX15,AUX16,AUX17,AUX18,AUX19,AUX20,AUX21,AUX22,AUX23,AUX24,AUX25,AUX26,AUX27,AUX28,AUX29,FL,FR"
      }
    }
  }
]
```

Restart wireplumber, etc.

    systemctl --user restart wireplumber pipewire pipewire-pulse

And you should start getting audio out automatically.  In my experience, after restarting I have had to restart already opened processes so that wireplumber tries to link thier audio again, but it works without issue after.
