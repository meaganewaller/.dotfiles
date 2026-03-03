function speak --description "Text-to-speech using piper"
  piper-tts --model ~/.local/share/piper/fr_FR-tom-medium.onnx --output-raw | ffplay -f s16le -ar 44100 -nodisp -autoexit -af "atempo=1.2" -
end
