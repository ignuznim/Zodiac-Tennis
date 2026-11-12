// PROTOTYPE - NOT FOR PRODUCTION
// Question: 동물마다 다른 능력치가 실제로 다른 플레이 방식을 만들고, 긴 5세트 경기 내내 랠리가 재미있는가?
// Date: 2026-11-12
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },

  // ---- Match rules (real tennis) ----
  sets_to_win: { value: 3, min: 1, max: 3, step: 1 },        // sets needed to win (3 = best of five)
  games_per_set: { value: 6, min: 2, max: 6, step: 1 },      // games to take a set, two clear
  tiebreak_points: { value: 7, min: 5, max: 10, step: 1 },   // tiebreak target, two clear
  final_tiebreak_points: { value: 10, min: 7, max: 12, step: 1 }, // fifth-set tiebreak target
  point_pause: { value: 1.7, min: 0.8, max: 4, step: 0.1 },  // seconds between points

  // ---- Ball and court (metres, seconds) ----
  gravity: { value: 9.8, min: 6, max: 14, step: 0.2 },       // m/s^2
  net_height: { value: 0.95, min: 0.7, max: 1.2, step: 0.05 },
  bounce: { value: 0.72, min: 0.4, max: 0.9, step: 0.02 },   // height kept on a bounce
  bounce_pace: { value: 0.6, min: 0.3, max: 0.9, step: 0.02 },      // pace kept on a bounce
  bounce_pace_spin: { value: 0.045, min: 0, max: 0.1, step: 0.005 }, // more pace kept per spin point
  drop_bounce: { value: 0.46, min: 0.2, max: 0.7, step: 0.02 },     // a drop shot's bounce height
  drop_pace: { value: 0.36, min: 0.1, max: 0.6, step: 0.02 },       // a drop shot's pace after the bounce
  drop_pace_spin: { value: 0.04, min: 0, max: 0.08, step: 0.005 },  // pace a drop loses per spin point

  // ---- Shots ----
  stroke_v: { value: 12.5, min: 8, max: 20, step: 0.5 },     // m/s, a stroke at power 0
  stroke_v_pow: { value: 1.3, min: 0, max: 3, step: 0.1 },   // m/s more per power point
  power_bonus: { value: 0.42, min: 0.1, max: 0.8, step: 0.02 }, // speed gained by a full power shot
  smash_bonus: { value: 0.55, min: 0.2, max: 1, step: 0.05 },   // speed gained by a smash
  drop_v: { value: 7.5, min: 5, max: 11, step: 0.5 },        // m/s, a drop shot
  lob_time: { value: 1.9, min: 1.4, max: 2.6, step: 0.1 },   // seconds a lob hangs
  serve_v: { value: 17, min: 12, max: 26, step: 0.5 },       // m/s, a first serve at power 0
  serve_v_pow: { value: 1.8, min: 0, max: 3, step: 0.1 },    // m/s more per power point
  second_serve: { value: 0.8, min: 0.6, max: 1, step: 0.02 },// second-serve speed factor
  toss_v: { value: 5.4, min: 4, max: 7, step: 0.1 },         // m/s, the toss
  aim_x: { value: 3.1, min: 2, max: 3.9, step: 0.1 },        // metres from centre a side shot aims
  err_stroke: { value: 0.62, min: 0.2, max: 1.5, step: 0.02 },// metres of scatter on a stroke
  err_serve: { value: 0.6, min: 0.2, max: 1.5, step: 0.02 }, // metres of scatter on a first serve
  err_spin: { value: 0.1, min: 0, max: 0.2, step: 0.01 },    // scatter removed per spin point
  err_power: { value: 1.3, min: 1, max: 2, step: 0.05 },     // scatter factor of a power shot
  fatigue_err: { value: 0.8, min: 0, max: 2, step: 0.1 },    // extra scatter when out of stamina
  fatigue_pace: { value: 0.15, min: 0, max: 0.4, step: 0.01 },// shot speed lost when out of stamina

  // ---- The three courts: a factor on the bounce height and on the pace kept ----
  hard_bounce: { value: 1, min: 0.7, max: 1.3, step: 0.02 }, hard_pace: { value: 1, min: 0.7, max: 1.3, step: 0.02 },
  grass_bounce: { value: 0.86, min: 0.7, max: 1.3, step: 0.02 }, grass_pace: { value: 1.12, min: 0.7, max: 1.3, step: 0.02 },   // low and fast
  clay_bounce: { value: 1.12, min: 0.7, max: 1.3, step: 0.02 }, clay_pace: { value: 0.86, min: 0.7, max: 1.3, step: 0.02 },     // high and slow

  // ---- Slice, backhand, the smash and the serve's timing ----
  slice_v: { value: 0.78, min: 0.5, max: 1, step: 0.02 },        // a slice's speed, as a share of a stroke's
  slice_bounce: { value: 0.5, min: 0.3, max: 0.8, step: 0.02 },  // a slice stays low
  slice_pace: { value: 0.74, min: 0.4, max: 0.95, step: 0.02 },  // and skids on
  backhand_pace: { value: 0.94, min: 0.7, max: 1, step: 0.01 },  // a backhand's speed against a forehand's
  smash_min_z: { value: 1.7, min: 1.2, max: 2.4, step: 0.05 },   // metres: a ball this high can be smashed
  wild_err: { value: 2.2, min: 1, max: 4, step: 0.1 },           // scatter of a smash swung at a low ball
  serve_fault_q: { value: 0.4, min: 0.1, max: 0.8, step: 0.02 }, // first serve: timing under this is a fault
  serve_fault_q2: { value: 0.2, min: 0, max: 0.6, step: 0.02 },  // second serve: a wider window

  // ---- Timing ----
  tap_window: { value: 0.24, min: 0.12, max: 0.4, step: 0.01 },   // s a swing waits for the ball (the buffer)
  sweet_window: { value: 0.16, min: 0.06, max: 0.3, step: 0.01 }, // s before contact that counts as sweet
  charge_time: { value: 0.75, min: 0.4, max: 1.5, step: 0.05 },   // s of holding for a full power shot
  release_window: { value: 0.2, min: 0.1, max: 0.4, step: 0.01 }, // s a released power swing waits
  swing_cool: { value: 0.26, min: 0.1, max: 0.6, step: 0.02 },    // s before the next swing

  // ---- Movement and the five stats (each stat runs 1 to 5) ----
  run_v: { value: 4.7, min: 3, max: 7, step: 0.1 },          // m/s at speed 0
  run_v_speed: { value: 0.55, min: 0, max: 1, step: 0.05 },  // m/s more per speed point
  accel: { value: 22, min: 10, max: 50, step: 1 },           // m/s^2 at reflex 0
  accel_reflex: { value: 8, min: 0, max: 15, step: 1 },      // m/s^2 more per reflex point
  reach: { value: 1.45, min: 1, max: 2.2, step: 0.05 },      // metres at reflex 0
  reach_reflex: { value: 0.12, min: 0, max: 0.25, step: 0.01 }, // metres more per reflex point
  charge_slow: { value: 0.45, min: 0.2, max: 1, step: 0.05 },// run speed kept while charging
  stam_base: { value: 55, min: 30, max: 100, step: 5 },      // stamina at stamina 0
  stam_per: { value: 15, min: 5, max: 30, step: 1 },         // stamina more per stamina point
  stam_run: { value: 2.6, min: 0, max: 6, step: 0.1 },       // stamina a second of sprinting costs
  stam_shot: { value: 1.6, min: 0, max: 5, step: 0.1 },      // stamina a shot costs
  stam_power: { value: 7, min: 0, max: 15, step: 0.5 },      // stamina a full power shot costs
  stam_rest: { value: 1.2, min: 0, max: 5, step: 0.1 },      // stamina a second of standing gives back
  stam_point: { value: 5, min: 0, max: 20, step: 1 },        // stamina back between points
  stam_set: { value: 22, min: 0, max: 60, step: 2 },         // stamina back between sets
  tired_run: { value: 0.3, min: 0, max: 0.6, step: 0.02 },   // run speed lost at zero stamina

  // ---- The computer, three levels: 1 easy, 2 normal, 3 hard ----
  ai1_react: { value: 0.36, min: 0, max: 0.8, step: 0.02 },  // s before it starts to move
  ai2_react: { value: 0.22, min: 0, max: 0.8, step: 0.02 },
  ai3_react: { value: 0.1, min: 0, max: 0.8, step: 0.02 },
  ai1_timing: { value: 0.52, min: 0, max: 1, step: 0.02 },   // its average timing, 1 is sweet
  ai2_timing: { value: 0.72, min: 0, max: 1, step: 0.02 },
  ai3_timing: { value: 0.9, min: 0, max: 1, step: 0.02 },
  ai1_smart: { value: 0.25, min: 0, max: 1, step: 0.05 },    // how often it aims away from you
  ai2_smart: { value: 0.55, min: 0, max: 1, step: 0.05 },
  ai3_smart: { value: 0.88, min: 0, max: 1, step: 0.05 },
  ai1_variety: { value: 0.06, min: 0, max: 1, step: 0.02 },  // how often it drops, lobs or powers up
  ai2_variety: { value: 0.2, min: 0, max: 1, step: 0.02 },
  ai3_variety: { value: 0.38, min: 0, max: 1, step: 0.02 },
  ai1_run: { value: 0.84, min: 0.5, max: 1, step: 0.02 },    // share of its run speed it uses
  ai2_run: { value: 0.94, min: 0.5, max: 1, step: 0.02 },
  ai3_run: { value: 1, min: 0.5, max: 1, step: 0.02 },

  // ---- The twelve animals: power, stamina, spin, reflex, speed (each 1 to 5, 16 in all) ----
  rat_power: { value: 1, min: 1, max: 5, step: 1 }, rat_stamina: { value: 3, min: 1, max: 5, step: 1 }, rat_spin: { value: 4, min: 1, max: 5, step: 1 }, rat_reflex: { value: 5, min: 1, max: 5, step: 1 }, rat_speed: { value: 3, min: 1, max: 5, step: 1 },
  ox_power: { value: 5, min: 1, max: 5, step: 1 }, ox_stamina: { value: 5, min: 1, max: 5, step: 1 }, ox_spin: { value: 2, min: 1, max: 5, step: 1 }, ox_reflex: { value: 2, min: 1, max: 5, step: 1 }, ox_speed: { value: 2, min: 1, max: 5, step: 1 },
  tiger_power: { value: 5, min: 1, max: 5, step: 1 }, tiger_stamina: { value: 3, min: 1, max: 5, step: 1 }, tiger_spin: { value: 2, min: 1, max: 5, step: 1 }, tiger_reflex: { value: 3, min: 1, max: 5, step: 1 }, tiger_speed: { value: 3, min: 1, max: 5, step: 1 },
  rabbit_power: { value: 2, min: 1, max: 5, step: 1 }, rabbit_stamina: { value: 3, min: 1, max: 5, step: 1 }, rabbit_spin: { value: 2, min: 1, max: 5, step: 1 }, rabbit_reflex: { value: 4, min: 1, max: 5, step: 1 }, rabbit_speed: { value: 5, min: 1, max: 5, step: 1 },
  dragon_power: { value: 4, min: 1, max: 5, step: 1 }, dragon_stamina: { value: 2, min: 1, max: 5, step: 1 }, dragon_spin: { value: 5, min: 1, max: 5, step: 1 }, dragon_reflex: { value: 3, min: 1, max: 5, step: 1 }, dragon_speed: { value: 2, min: 1, max: 5, step: 1 },
  snake_power: { value: 2, min: 1, max: 5, step: 1 }, snake_stamina: { value: 3, min: 1, max: 5, step: 1 }, snake_spin: { value: 5, min: 1, max: 5, step: 1 }, snake_reflex: { value: 4, min: 1, max: 5, step: 1 }, snake_speed: { value: 2, min: 1, max: 5, step: 1 },
  horse_power: { value: 3, min: 1, max: 5, step: 1 }, horse_stamina: { value: 4, min: 1, max: 5, step: 1 }, horse_spin: { value: 1, min: 1, max: 5, step: 1 }, horse_reflex: { value: 3, min: 1, max: 5, step: 1 }, horse_speed: { value: 5, min: 1, max: 5, step: 1 },
  sheep_power: { value: 2, min: 1, max: 5, step: 1 }, sheep_stamina: { value: 5, min: 1, max: 5, step: 1 }, sheep_spin: { value: 4, min: 1, max: 5, step: 1 }, sheep_reflex: { value: 3, min: 1, max: 5, step: 1 }, sheep_speed: { value: 2, min: 1, max: 5, step: 1 },
  monkey_power: { value: 2, min: 1, max: 5, step: 1 }, monkey_stamina: { value: 2, min: 1, max: 5, step: 1 }, monkey_spin: { value: 4, min: 1, max: 5, step: 1 }, monkey_reflex: { value: 5, min: 1, max: 5, step: 1 }, monkey_speed: { value: 3, min: 1, max: 5, step: 1 },
  rooster_power: { value: 3, min: 1, max: 5, step: 1 }, rooster_stamina: { value: 3, min: 1, max: 5, step: 1 }, rooster_spin: { value: 3, min: 1, max: 5, step: 1 }, rooster_reflex: { value: 4, min: 1, max: 5, step: 1 }, rooster_speed: { value: 3, min: 1, max: 5, step: 1 },
  dog_power: { value: 3, min: 1, max: 5, step: 1 }, dog_stamina: { value: 4, min: 1, max: 5, step: 1 }, dog_spin: { value: 2, min: 1, max: 5, step: 1 }, dog_reflex: { value: 3, min: 1, max: 5, step: 1 }, dog_speed: { value: 4, min: 1, max: 5, step: 1 },
  pig_power: { value: 4, min: 1, max: 5, step: 1 }, pig_stamina: { value: 5, min: 1, max: 5, step: 1 }, pig_spin: { value: 3, min: 1, max: 5, step: 1 }, pig_reflex: { value: 2, min: 1, max: 5, step: 1 }, pig_speed: { value: 2, min: 1, max: 5, step: 1 },
};
