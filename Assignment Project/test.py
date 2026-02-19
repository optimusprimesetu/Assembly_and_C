import pygame
import numpy as np
import time
import json
import os

pygame.mixer.pre_init(44100, -16, 2, 512)
pygame.init()
screen = pygame.display.set_mode((400, 300))
pygame.display.set_caption("Intrusive Rhythm - FINAL ENGINE")

def generate_tone(frequency, duration, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    t = np.linspace(0, duration, n_samples, False)
    signal = np.sign(np.sin(2 * np.pi * frequency * t))
    samples = (signal * 32767 * volume).astype(np.int16)
    return pygame.sndarray.make_sound(np.column_stack((samples, samples)))

# 1-second tones that we can cut off or let play
SND_HIGH = generate_tone(880, 1.0, 0.4) 
FAIL_SOUND = generate_tone(110, 0.3, 0.6)  

RHYTHM_LIBRARY = {}

# Load custom recordings
if os.path.exists("my_thoughts.json"):
    with open("my_thoughts.json", "r") as f:
        custom_data = json.load(f)
        for name, notes in custom_data.items():
            # Handle old recordings that were just flat arrays of numbers
            if isinstance(notes[0], (int, float)):
                notes = [{"time": t, "duration": 0.1} for t in notes]
            
            RHYTHM_LIBRARY[name] = {"notes": notes, "tolerance": 0.20}
    print(f"✅ Loaded {len(custom_data)} custom thoughts.")
else:
    print("❌ No custom thoughts found. Run the recorder first!")
    exit()

def play_level(level_name, config):
    tolerance = config["tolerance"]
    expected_notes = config["notes"].copy()
    
    print(f"\n=====================================")
    print(f"🧠 THOUGHT: {level_name.upper()}")
    print(f"=====================================")
    
    # --- PHASE 1: LISTEN ---
    screen.fill((50, 0, 0))
    pygame.display.flip()
    print("🎧 LISTEN...")
    time.sleep(1)
    
    playback_queue = expected_notes.copy()
    start_listen_time = time.time()
    
    while playback_queue:
        current_time = time.time() - start_listen_time
        if current_time >= playback_queue[0]["time"]:
            note = playback_queue.pop(0)
            # maxtime automatically cuts the sound off after the duration ends!
            play_ms = int(note["duration"] * 1000)
            SND_HIGH.play(maxtime=play_ms)
            
            if note["duration"] > 0.25: print("🎵=== ", end="", flush=True)
            else: print("♪ ", end="", flush=True)
            
        pygame.event.pump()
    
    time.sleep(1.0) 

    # --- PHASE 2: PLAY ---
    screen.fill((0, 50, 0))
    pygame.display.flip()
    print("\n\n👉 HIT SPACE ON THE FIRST BEAT TO START...")
    
    pygame.event.clear() 
    waiting = True
    start_time = 0
    
    # We now track if the player is currently holding a long note
    active_hold_note = None 
    
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT: exit()
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                start_time = time.time()
                
                first_note = expected_notes[0]
                if first_note["time"] <= tolerance:
                    expected_notes.pop(0)
                    
                    if first_note["duration"] > 0.25:
                        SND_HIGH.play(loops=-1) # Start holding
                        active_hold_note = first_note
                        print("\n⬇️ HOLD... ", end="", flush=True)
                    else:
                        SND_HIGH.play(maxtime=100)
                        print("\n✅ ", end="", flush=True)
                
                waiting = False
    
    total_duration = expected_notes[-1]["time"] + expected_notes[-1]["duration"] if expected_notes else 0
    hits = 1 
    misses = 0

    while time.time() - start_time < total_duration + tolerance + 0.5:
        current_time = time.time() - start_time

        # Check for missed un-hit notes
        if expected_notes and current_time > expected_notes[0]["time"] + tolerance:
            expected_notes.pop(0)
            FAIL_SOUND.play()
            print("❌(missed) ", end="", flush=True)
            misses += 1

        for event in pygame.event.get():
            if event.type == pygame.QUIT: exit()
            
            # --- KEY DOWN (Starting a note) ---
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                hit = False
                for i, expected in enumerate(expected_notes):
                    if abs(current_time - expected["time"]) <= tolerance:
                        drift_offset = current_time - expected["time"]
                        for j in range(len(expected_notes)):
                            expected_notes[j]["time"] += drift_offset 
                            
                        # Is it a Tap or a Hold?
                        if expected["duration"] > 0.25:
                            active_hold_note = expected
                            SND_HIGH.play(loops=-1)
                            print("⬇️ ", end="", flush=True)
                        else:
                            SND_HIGH.play(maxtime=100)
                            print("✅ ", end="", flush=True)
                            hits += 1
                            
                        expected_notes.pop(i)
                        hit = True
                        break
                
                if not hit:
                    FAIL_SOUND.play()
                    print("❌(bad start) ", end="", flush=True)
                    misses += 1

            # --- KEY UP (Ending a hold) ---
            elif event.type == pygame.KEYUP and event.key == pygame.K_SPACE:
                SND_HIGH.stop() # Always stop the sound
                
                if active_hold_note:
                    expected_release_time = active_hold_note["time"] + active_hold_note["duration"]
                    
                    if abs(current_time - expected_release_time) <= tolerance:
                        print("⬆️✅ ", end="", flush=True)
                        hits += 1
                    else:
                        FAIL_SOUND.play()
                        print("⬆️❌(bad release) ", end="", flush=True)
                        misses += 1
                        
                    active_hold_note = None # Clear the hold

    print(f"\n\n📊 SCORE: {hits} | MISSES: {misses}")
    if misses == 0:
        print("🎉 PERFECT CLEAR!")
    else:
        print("🤡 GAG TRIGGERED!")
    time.sleep(2)

if __name__ == "__main__":
    for name, config in RHYTHM_LIBRARY.items():
        play_level(name, config)
    pygame.quit()