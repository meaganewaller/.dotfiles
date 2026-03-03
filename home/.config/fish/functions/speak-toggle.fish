function speak-toggle --description "Toggle TTS on/off"
  set -l state_file ~/.local/state/speak-enabled
  mkdir -p ~/.local/state

  if test -f $state_file
    rm $state_file
    paplay /usr/share/sounds/freedesktop/stereo/device-removed.oga &
  else
    touch $state_file
    paplay /usr/share/sounds/freedesktop/stereo/device-added.oga &
  end
end
