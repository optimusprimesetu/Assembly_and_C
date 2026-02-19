import pygame
import numpy as np
import time
import json
import os

pygame.mixer.pre_init(44100, -16, 2, 512)
pygame.init()
screen = pygame.display.set_mode((400, 300))
pygame.display.set_caption("Intrusive Rhythm - Space Only Mode")

def generate_tone(frequency, duration, volume=0.4):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    t = np.linspace(0, duration, n_samples, False)
    signal = np.sign(np.sin(2 * np.pi * frequency * t))
    samples = (signal * 32767 * volume).astype(np.int16)
    return pygame.sndarray.make_sound(np.column_stack((samples, samples)))

FAIL_SOUND = generate_tone(110, 0.3, 0.6)

if os.path.exists("my_thoughts2.json"):
    with open("my_thoughts2.json", "r") as f:
        custom_data = json.load(f)
    # Reverse to play latest first
    REVERSED_LEVELS = list(custom_data.items())[::-1]
else:
    print("❌ No recordings found!")
    exit()

def play_level(level_name, notes):
    tolerance = 0.22 # Slightly more forgiving for space-only play
    expected_notes = notes.copy()
    
    print(f"\n🧠 THOUGHT: {level_name.upper()}")

    # --- PHASE 1: LISTEN ---
    screen.fill((40, 40, 80)) # Blue-ish for listen
    pygame.display.flip()
    print("🎧 LISTEN TO THE PITCHES...")
    
    start_listen = time.time()
    playback_queue = expected_notes.copy()
    while playback_queue:
        curr = time.time() - start_listen
        if curr >= playback_queue[0]["time"]:
            n = playback_queue.pop(0)
            freq = n.get("freq", 880)
            ms = int(n["duration"] * 1000)
            generate_tone(freq, n["duration"]).play(maxtime=ms)
        pygame.event.pump()
    
    time.sleep(1.0)

    # --- PHASE 2: PLAY (SPACE ONLY) ---
    screen.fill((40, 80, 40)) # Green-ish for play
    pygame.display.flip()
    print("\n👉 USE [SPACE] TO REPLICATE THE RHYTHM...")
    
    pygame.event.clear()
    waiting = True
    start_time = 0
    hits, misses = 0, 0
    current_active_sound = None
    active_hold_note = None

    # Sync start
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                start_time = time.time()
                first = expected_notes[0]
                if first["time"] <= tolerance:
                    expected_notes.pop(0)
                    hits += 1
                    # Play the SPECIFIC pitch recorded for this note
                    current_active_sound = generate_tone(first.get("freq", 880), 1.0)
                    current_active_sound.play(loops=-1)
                    active_hold_note = first
                    print("✅ ", end="", flush=True)
                waiting = False

    total_time = notes[-1]["time"] + notes[-1]["duration"]
    
    while (time.time() - start_time) < (total_time + 0.8):
        current_time = time.time() - start_time

        # Miss check
        if expected_notes and current_time > expected_notes[0]["time"] + tolerance:
            expected_notes.pop(0)
            FAIL_SOUND.play()
            print("❌ ", end="", flush=True)
            misses += 1

        for event in pygame.event.get():
            if event.type == pygame.QUIT: exit()
            
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                hit_found = False
                for i, exp in enumerate(expected_notes):
                    if abs(current_time - exp["time"]) <= tolerance:
                        # Drift sync
                        drift = current_time - exp["time"]
                        for n in expected_notes: n["time"] += drift
                        
                        # Trigger the recorded pitch even though user hit Space
                        current_active_sound = generate_tone(exp.get("freq", 880), 1.0)
                        current_active_sound.play(loops=-1)
                        active_hold_note = exp
                        
                        expected_notes.pop(i)
                        hits += 1
                        hit_found = True
                        print("✅ ", end="", flush=True)
                        break
                
                if not hit_found:
                    FAIL_SOUND.play()
                    misses += 1

            elif event.type == pygame.KEYUP and event.key == pygame.K_SPACE:
                if current_active_sound:
                    current_active_sound.stop()
                
                if active_hold_note:
                    expected_end = active_hold_note["time"] + active_hold_note["duration"]
                    # If they let go too early or too late
                    if abs(current_time - expected_end) > tolerance:
                        print(" (Short) ", end="", flush=True)
                        # We don't necessarily count a bad release as a full miss 
                        # unless you want it to be strict
                    active_hold_note = None

    print(f"\n📊 SCORE: {hits} Hits | {misses} Misses")
    time.sleep(1)

if __name__ == "__main__":
    for name, notes in REVERSED_LEVELS:
        play_level(name, notes)
    pygame.quit()