import pygame
import time
import json
import numpy as np
import os

pygame.mixer.pre_init(44100, -16, 2, 512)
pygame.init()
screen = pygame.display.set_mode((400, 300))
pygame.display.set_caption("Multi-Pitch Rhythm Recorder")

# Frequency mapping: Q W E (Lower) | R (Mid/Original) | T Y U (Higher)
# Using a basic musical scale (A Major ish)
KEY_MAP = {
    pygame.K_q: 440, # A4
    pygame.K_w: 554, # C#5
    pygame.K_e: 659, # E5
    pygame.K_r: 880, # A5 (Original Space frequency)
    pygame.K_t: 1108, # C#6
    pygame.K_y: 1318, # E6
    pygame.K_u: 1760  # A6
}

def generate_tone(frequency, duration, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    t = np.linspace(0, duration, n_samples, False)
    signal = np.sign(np.sin(2 * np.pi * frequency * t))
    samples = (signal * 32767 * volume).astype(np.int16)
    return pygame.sndarray.make_sound(np.column_stack((samples, samples)))

# Pre-generate sounds for each key to avoid lag during recording
SOUNDS = {key: generate_tone(freq, 1.0) for key, freq in KEY_MAP.items()}

def record():
    screen.fill((50, 50, 50))
    pygame.display.flip()
    print("\n🔴 MULTI-KEY RECORDER READY.")
    print("👉 Keys: Q W E [R] T Y U | Hit ENTER to finish.")
    
    recorded_notes = []
    start_time = 0
    recording = False
    waiting = True
    
    # Track multiple active notes
    active_notes = {} # Format: {key: start_time}
    
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT: return
            
            if event.type == pygame.KEYDOWN:
                if event.key in KEY_MAP:
                    if not recording:
                        start_time = time.time()
                        recording = True
                        print("\n▶️ RECORDING...")
                    
                    # Store start time and frequency, play sound
                    active_notes[event.key] = time.time()
                    SOUNDS[event.key].play(loops=-1)
                    print(f"[{pygame.key.name(event.key)}⬇️]", end="", flush=True)
                
                elif event.key == pygame.K_RETURN and recording:
                    waiting = False

            elif event.type == pygame.KEYUP:
                if event.key in active_notes:
                    note_start = active_notes.pop(event.key)
                    duration = time.time() - note_start
                    timestamp = note_start - start_time
                    
                    recorded_notes.append({
                        "time": timestamp, 
                        "duration": duration,
                        "freq": KEY_MAP[event.key]
                    })
                    
                    SOUNDS[event.key].stop()
                    print("⬆️ ", end="", flush=True)

    if recorded_notes:
        save_recording(recorded_notes)

def save_recording(notes):
    filename = "my_thoughts2.json"
    data = {}
    if os.path.exists(filename):
        with open(filename, "r") as f:
            try: data = json.load(f)
            except: pass
                
    thought_name = f"Thought {len(data) + 1}"
    data[thought_name] = notes
    with open(filename, "w") as f:
        json.dump(data, f, indent=4)
    print(f"\n💾 Saved as '{thought_name}'")

if __name__ == "__main__":
    record()
    pygame.quit()


# "Thought 4": [
#         {
#             "time": 0.0,
#             "duration": 0.3945167064666748,
#             "freq": 1318
#         },
#         {
#             "time": 0.30207204818725586,
#             "duration": 0.2597348690032959,
#             "freq": 1108
#         },
#         {
#             "time": 0.6110491752624512,
#             "duration": 0.07178139686584473,
#             "freq": 1318
#         },
#         {
#             "time": 0.7228970527648926,
#             "duration": 0.08719038963317871,
#             "freq": 1108
#         },
#         {
#             "time": 0.8441743850708008,
#             "duration": 0.08187031745910645,
#             "freq": 1318
#         },
#         {
#             "time": 0.9350745677947998,
#             "duration": 0.05619621276855469,
#             "freq": 1108
#         },
#         {
#             "time": 1.0657002925872803,
#             "duration": 0.14316773414611816,
#             "freq": 1318
#         },
#         {
#             "time": 1.1783108711242676,
#             "duration": 0.22806859016418457,
#             "freq": 1108
#         },
#         {
#             "time": 1.4997525215148926,
#             "duration": 0.3033456802368164,
#             "freq": 1318
#         },
#         {
#             "time": 1.8227803707122803,
#             "duration": 0.4448099136352539,
#             "freq": 554
#         },
#         {
#             "time": 2.1367404460906982,
#             "duration": 0.14103174209594727,
#             "freq": 880
#         },
#         {
#             "time": 2.4658663272857666,
#             "duration": 0.15833187103271484,
#             "freq": 1108
#         },
#         {
#             "time": 2.475382089614868,
#             "duration": 0.5565621852874756,
#             "freq": 554
#         },
#         {
#             "time": 2.9002625942230225,
#             "duration": 0.2593841552734375,
#             "freq": 1318
#         },
#         {
#             "time": 3.5516839027404785,
#             "duration": 0.07118368148803711,
#             "freq": 1108
#         },
#         {
#             "time": 3.6067819595336914,
#             "duration": 0.09327101707458496,
#             "freq": 659
#         },
#         {
#             "time": 3.7536423206329346,
#             "duration": 0.11120009422302246,
#             "freq": 1318
#         },
#         {
#             "time": 3.8289332389831543,
#             "duration": 0.3167402744293213,
#             "freq": 659
#         },
#         {
#             "time": 4.0415198802948,
#             "duration": 0.12419843673706055,
#             "freq": 554
#         },
#         {
#             "time": 4.107603073120117,
#             "duration": 0.6176753044128418,
#             "freq": 1760
#         },
#         {
#             "time": 4.8198957443237305,
#             "duration": 1.1078784465789795,
#             "freq": 659
#         },
#         {
#             "time": 4.603167772293091,
#             "duration": 1.3516981601715088,
#             "freq": 554
#         },
#         {
#             "time": 5.154236793518066,
#             "duration": 0.811182975769043,
#             "freq": 1108
#         },
#         {
#             "time": 5.163756608963013,
#             "duration": 0.8111817836761475,
#             "freq": 1318
#         },
#         {
#             "time": 8.584465265274048,
#             "duration": 0.42705225944519043,
#             "freq": 659
#         },
#         {
#             "time": 8.574917793273926,
#             "duration": 0.4466276168823242,
#             "freq": 554
#         },
#         {
#             "time": 8.565395832061768,
#             "duration": 0.46665191650390625,
#             "freq": 880
#         }
#     ]