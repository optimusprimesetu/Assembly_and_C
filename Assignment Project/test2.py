import pygame
import numpy as np
import time
import json
import os

pygame.mixer.pre_init(44100, -16, 2, 512)
pygame.init()
screen = pygame.display.set_mode((400, 300))
pygame.display.set_caption("Multi-Pitch Rhythm Engine")

def generate_tone(frequency, duration, volume=0.4):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    t = np.linspace(0, duration, n_samples, False)
    signal = np.sign(np.sin(2 * np.pi * frequency * t))
    samples = (signal * 32767 * volume).astype(np.int16)
    return pygame.sndarray.make_sound(np.column_stack((samples, samples)))

FAIL_SOUND = generate_tone(110, 0.3, 0.6)

# Key Mapping for user input
KEY_FREQ_MAP = {
    pygame.K_q: 440, pygame.K_w: 554, pygame.K_e: 659,
    pygame.K_r: 880, pygame.K_t: 1108, pygame.K_y: 1318, pygame.K_u: 1760
}

if os.path.exists("my_thoughts2.json"):
    with open("my_thoughts2.json", "r") as f:
        custom_data = json.load(f)
    # Reverse order: Latest first
    REVERSED_LEVELS = list(custom_data.items())[::-1]
    print(f"✅ Loaded {len(REVERSED_LEVELS)} thoughts (Latest First).")
else:
    print("❌ No recordings found. Run recorder.py first!")
    exit()

def play_level(level_name, notes):
    tolerance = 0.20
    expected_notes = notes.copy()
    active_sounds = {} 
    
    print(f"\n{'='*30}\n🧠 THOUGHT: {level_name.upper()}\n{'='*30}")

    # --- PHASE 1: LISTEN ---
    screen.fill((50, 0, 0))
    pygame.display.flip()
    print("🎧 LISTEN...")
    
    listen_queue = expected_notes.copy()
    start_listen = time.time()
    while listen_queue:
        curr = time.time() - start_listen
        if curr >= listen_queue[0]["time"]:
            n = listen_queue.pop(0)
            freq = n.get("freq", 880)
            duration_ms = int(n["duration"] * 1000)
            generate_tone(freq, n["duration"]).play(maxtime=duration_ms)
            print("♪" if n["duration"] < 0.25 else "🎵===", end=" ", flush=True)
        pygame.event.pump()
    
    time.sleep(1.2)

    # --- PHASE 2: PLAY ---
    screen.fill((0, 50, 0))
    pygame.display.flip()
    print("\n\n👉 PRESS ANY MAPPED KEY TO START...")
    
    pygame.event.clear()
    waiting = True
    start_time = 0
    hits, misses = 0, 0
    active_hold_note = None

    # Wait for first hit
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT: exit()
            if event.type == pygame.KEYDOWN and event.key in KEY_FREQ_MAP:
                start_time = time.time()
                # Check if first note matches
                first = expected_notes[0]
                if first["time"] <= tolerance:
                    expected_notes.pop(0)
                    hits += 1
                    freq = first.get("freq", 880)
                    active_sounds[event.key] = generate_tone(freq, 1.0)
                    active_sounds[event.key].play(loops=-1)
                    active_hold_note = first
                    print(f"✅({pygame.key.name(event.key)}) ", end="", flush=True)
                waiting = False

    total_time = notes[-1]["time"] + notes[-1]["duration"]
    
    # Gameplay Loop
    while (time.time() - start_time) < (total_time + 1.0):
        current_time = time.time() - start_time

        # Check for missed notes
        if expected_notes and current_time > expected_notes[0]["time"] + tolerance:
            expected_notes.pop(0)
            FAIL_SOUND.play()
            print("❌(miss) ", end="", flush=True)
            misses += 1

        for event in pygame.event.get():
            if event.type == pygame.QUIT: exit()
            
            if event.type == pygame.KEYDOWN and event.key in KEY_FREQ_MAP:
                hit_found = False
                for i, exp in enumerate(expected_notes):
                    # Check time AND frequency match
                    if abs(current_time - exp["time"]) <= tolerance:
                        # Drift correction
                        drift = current_time - exp["time"]
                        for n in expected_notes: n["time"] += drift
                        
                        freq = exp.get("freq", 880)
                        active_sounds[event.key] = generate_tone(freq, 1.0)
                        active_sounds[event.key].play(loops=-1)
                        active_hold_note = exp
                        
                        expected_notes.pop(i)
                        hits += 1
                        hit_found = True
                        print(f"✅ ", end="", flush=True)
                        break
                
                if not hit_found:
                    FAIL_SOUND.play()
                    print("❌ ", end="", flush=True)
                    misses += 1

            elif event.type == pygame.KEYUP and event.key in KEY_FREQ_MAP:
                if event.key in active_sounds:
                    active_sounds[event.key].stop()
                    del active_sounds[event.key]
                
                if active_hold_note:
                    expected_end = active_hold_note["time"] + active_hold_note["duration"]
                    if abs(current_time - expected_end) > tolerance:
                        print("⬆️❌ ", end="", flush=True)
                        misses += 1
                    active_hold_note = None

    print(f"\n\n📊 RESULTS: {hits} Hits | {misses} Misses")
    time.sleep(1.5)

if __name__ == "__main__":
    for name, notes in REVERSED_LEVELS:
        play_level(name, notes)
    pygame.quit()