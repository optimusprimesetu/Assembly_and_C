import pygame
import time
import json
import numpy as np
import os

pygame.mixer.pre_init(44100, -16, 2, 512)
pygame.init()
screen = pygame.display.set_mode((400, 300))
pygame.display.set_caption("Intrusive Rhythm - HOLD RECORDER")

def generate_tone(frequency, duration, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    t = np.linspace(0, duration, n_samples, False)
    signal = np.sign(np.sin(2 * np.pi * frequency * t))
    samples = (signal * 32767 * volume).astype(np.int16)
    return pygame.sndarray.make_sound(np.column_stack((samples, samples)))

# We use a 1-second tone, but we will loop it infinitely while holding
SND_TAP = generate_tone(880, 1.0, 0.5)

def record():
    screen.fill((50, 50, 50))
    pygame.display.flip()
    print("\n🔴 RECORDER READY.")
    print("👉 Tap for quick notes, HOLD for long notes.")
    print("👉 Hit ENTER when you are finished.")
    
    recorded_notes = []
    start_time = 0
    recording = False
    waiting = True
    
    note_start = 0
    is_holding = False
    
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT: return
            
            # 1. KEY GOES DOWN (Start Note)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    if not recording:
                        start_time = time.time()
                        recording = True
                        print("\n▶️ RECORDING... (Hit ENTER to stop)")
                    
                    note_start = time.time()
                    is_holding = True
                    SND_TAP.play(loops=-1) # Loop the sound infinitely while held
                    print("⬇️", end="", flush=True)
                
                elif event.key == pygame.K_RETURN and recording:
                    print(f"\n⏹️ STOPPED. Recorded {len(recorded_notes)} notes.")
                    waiting = False

            # 2. KEY GOES UP (End Note & Calculate Duration)
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_SPACE and is_holding:
                    duration = time.time() - note_start
                    timestamp = note_start - start_time
                    
                    # Save the note as a dictionary containing both time and duration
                    recorded_notes.append({"time": timestamp, "duration": duration})
                    
                    SND_TAP.stop() # Stop the looping sound
                    is_holding = False
                    
                    if duration > 0.25:
                        print(f" (Held {duration:.2f}s) ", end="", flush=True)
                    else:
                        print("⬆️ ", end="", flush=True)

    if recorded_notes:
        save_recording(recorded_notes)

def save_recording(notes):
    filename = "my_thoughts.json"
    data = {}
    if os.path.exists(filename):
        with open(filename, "r") as f:
            try: data = json.load(f)
            except: pass
                
    thought_name = f"Custom Thought {len(data) + 1}"
    data[thought_name] = notes
    with open(filename, "w") as f:
        json.dump(data, f, indent=4)
    print(f"\n💾 Saved as '{thought_name}' in {filename}")

if __name__ == "__main__":
    record()
    pygame.quit()