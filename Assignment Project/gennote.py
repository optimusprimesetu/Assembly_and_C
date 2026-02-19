import wave
import struct
import math
import random

def generate_random_notes(filename, num_notes=5, duration_per_note=0.5):
    # Audio settings
    sample_rate = 44100.0  # Standard CD quality
    amplitude = 16000      # Volume (out of 32767 for 16-bit PCM)
    
    # Common musical frequencies (C4 to C5)
    frequencies = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
    
    with wave.open(filename, 'w') as wav_file:
        # Set parameters: 1 channel (Mono), 2 bytes per sample, 44100 sample rate
        wav_file.setparams((1, 2, int(sample_rate), 0, 'NONE', 'not compressed'))
        
        for _ in range(num_notes):
            freq = random.choice(frequencies)
            num_samples = int(duration_per_note * sample_rate)
            
            for i in range(num_samples):
                # Calculate the sine wave value
                value = amplitude * math.sin(2 * math.pi * freq * (i / sample_rate))
                # Pack the value into binary format (h = short/16-bit integer)
                data = struct.pack('<h', int(value))
                wav_file.writeframesraw(data)

# Generate the 3 files
for i in range(1, 4):
    file_name = f"note{i}.wav"
    generate_random_notes(file_name)
    print(f"Generated: {file_name}")