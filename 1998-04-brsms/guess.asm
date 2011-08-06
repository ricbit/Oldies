; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: 
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80sing.inc
include z80fd.inc
include pmode.inc
include bit.inc
include vdp.inc
include blit.inc
include z80core.inc

extrn iset: dword
extrn isetFDCBxx: dword
extrn isetCBxx: dword
extrn sg1000: dword
extrn coleco: dword
extrn emulCB7F: near
extrn emulCB76: near
extrn emulCB46: near

public guess_table
public entry_basic
public entry_music

; --------------------------------------------------------------------

GUESS   macro crc,cartridge

        dd      crc
        dd      offset install_&cartridge
        dd      offset name_&cartridge

        endm

INSTALL macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        ret

        endm

INSTALL_LINE macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     linebyline,1
        ret

        endm

INSTALL_CACHE macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     imagetype,0
        ret

        endm

INSTALL_RASTER macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     linebyline,1
        mov     palette_raster,1
        ret

        endm

INSTALL_LCD macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     linebyline,1
        mov     palette_raster,1
        mov     lcdfilter,1
        ret

        endm

INSTALL_LIGHTGUN macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     linebyline,1
        mov     palette_raster,1
        mov     lightgun,1
        ret

        endm

INSTALL_SPRITE macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     linebyline,1
        mov     do_collision,1
        ret

        endm

INSTALL_SG1000 macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     sg1000,1
        ret

        endm

INSTALL_COLECO macro cartridge,vector,opcode

install_&cartridge:        
        mov     eax,offset custom_&cartridge
        mov     dword ptr [offset vector+opcode*4],eax
        mov     sg1000,1
        mov     coleco,1
        ret

        endm

CUSTOM  macro   cartridge,addr,opcode,delay

custom_&cartridge:
        cmp     edi,addr
        jne     emul&opcode
        
        call    emul&opcode
        
        dec     delay_counter
        cmp     delay_counter,50
        je      _ret

        mov     delay_counter,delay
        mov     ebp,0
        ret

        endm

CUSTOM2 macro   cartridge,addr1,addr2,opcode,delay
        local   custom_go

custom_&cartridge:
        cmp     edi,addr1
        je      custom_go

        cmp     edi,addr2
        jne     emul&opcode

custom_go:  
        call    emul&opcode
        
        dec     delay_counter
        jnz     _ret

        mov     delay_counter,delay
        mov     ebp,0
        ret

        endm

; --------

custom_zool:                
                mov     bl,vdpstatus
                test    byte ptr [offset vdpregs+0],BIT_4
                jnz     custom_zool_full
                mov     iline,0
                mov     vdpcond,0
                ret
custom_zool_full:
                and     vdpstatus,03Fh
                mov     iline,0
                mov     vdpcond,0
                ret

custom_sensible_soccer:
        cmp     edi,09B6Eh
        je      custom_sensible_soccer_go

        cmp     edi,0B9D1h
        je      custom_sensible_soccer_go

        cmp     edi,06DFh
        jne     emul3A

custom_sensible_soccer_go:        
        call    emul3A
        
        dec     delay_counter
        jnz     _ret

        mov     delay_counter,2
        mov     ebp,0
        ret

; --------

custom_tom_and_jerry:
        cmp     edi,018D7h
        je      custom_tom_and_jerry_go

        cmp     edi,01900h
        je      custom_tom_and_jerry_go

        cmp     edi,02C8h
        jne     emul7E

custom_tom_and_jerry_go:        
        call    emul7E
        
        dec     delay_counter
        jnz     _ret

        mov     delay_counter,2
        mov     ebp,0
        ret

CUSTOM alex_kidd_miracle,02EAh,7E,2
CUSTOM sonic_1,031Ch+3,FDCB46,2
CUSTOM sonic_2,0597h,7E,2
CUSTOM daffy_duck,073B9h,3A,2
CUSTOM phantasy_star,055h,3A,2
CUSTOM phantasy_star_brazilian,055h,3A,2
CUSTOM indiana_jones_crusade,0694h,3A,2
CUSTOM double_dragon,09F3h,7E,2
CUSTOM wonder_boy_3,0FEEh,3A,2
CUSTOM monica_castelo_dragao,0DAh,3A,2
CUSTOM sonic_chaos,0635h,7E,2
CUSTOM rastan,0FAh,FB,2
CUSTOM rtype_patch1,0CE5h,3A,2
CUSTOM rtype_patch2,04B4h,BE,2
CUSTOM bram_stoker_dracula,051BCh,3A,2
CUSTOM rainbow_islands,0E7h,00,2
CUSTOM megaman,03737h,FB,2
CUSTOM wonder_boy_2,0DAh,3A,2
CUSTOM alex_kidd_shinobi_world,04Ch,3A,2
CUSTOM sonic_1_gg,0327h+3,FDCB46,2
CUSTOM sonic_labyrinth,044Dh,3A,2
CUSTOM sonic_and_tails_2,0854h,7E,2
CUSTOM outrun_europe,03152h,3A,2
CUSTOM golvellius,07CFh,3A,2
CUSTOM altered_beast,0487h,3A,2
CUSTOM power_strike,012C8h,3A,2
CUSTOM samurai_spirits,0D5h,FB,2
CUSTOM fantasy_zone,0710h,3A,2
CUSTOM fantasy_zone_2,01Dh,3A,2
CUSTOM wonder_boy_1,0A8h,3A,2
CUSTOM spiderman_xmen,02E14h,3A,2
CUSTOM galaga_91,019Dh,3A,2
CUSTOM the_ottifants,027F4h,3A,2
CUSTOM lord_of_sword,0FCh,FB,2
CUSTOM rampage_patch1,037Ch,FB,2
CUSTOM rampage_patch2,0388h,3A,2
CUSTOM space_harrier_3d,03EA6h,7E,2
CUSTOM zaxxon_3d,019Dh,3A,2
CUSTOM spellcaster,0DC0h,3A,2
CUSTOM afterburner,0E3h,3A,2
CUSTOM super_tetris,03A9h,3A,2
CUSTOM secret_commando,0D2h,3A,2
CUSTOM the_ninja,018h,7E,2
CUSTOM miracle_warriors,0207Fh,7E,2
CUSTOM shinobi,0BD8h,3A,2
CUSTOM thunder_blade,0ECh,3A,2
CUSTOM golden_axe,0C0h,3A,2
CUSTOM space_harrier,059h,3A,2
CUSTOM fantasy_zone_the_maze,0ACh,3A,2
CUSTOM super_tennis,036Ah,3A,2
CUSTOM bomber_raid,04C4h,3A,2
CUSTOM moonwalker,02DBh,7E,2
CUSTOM strider,046Ch,3A,2
CUSTOM ultima_4_patch1,0427h,BE,2
CUSTOM ultima_4_patch2,0D0Dh,7E,2
CUSTOM final_bubble_bobble,0152h,C3,2
CUSTOM action_fighter,04B1h,3A,2
CUSTOM astro_warrior,0Eh,7E,2
CUSTOM astro_pitpot_patch1,0419Dh,3A,2
CUSTOM astro_pitpot_patch2,0Eh,7E,2
CUSTOM aztec_adventure,0524h,3A,2
CUSTOM alien_syndrome,02D8h,3A,2
CUSTOM pacmania,087h,3A,2
CUSTOM teddy_boy,0178h,3A,2
CUSTOM sailor_moon_s,015Ch,3A,2
CUSTOM ninja_princess,0B1h,7E,2
CUSTOM sonic_2_gg,05CDh,7E,2
CUSTOM transbot,027E2h,3A,2
CUSTOM marble_madness,0477Fh,3A,2
CUSTOM global_defense,0FC3h,3A,2
CUSTOM galaxy_force,0FAh,3A,2
CUSTOM ghouls_n_ghosts,0BDh,7E,4
CUSTOM parlour_games,061Bh,BE,2
CUSTOM deep_duck_trouble,0589h,7E,2
CUSTOM psychic_world,03CAh,7E,2
CUSTOM castle_of_illusion,04Ch,3A,2
CUSTOM california_games,077Dh,7E,2
CUSTOM out_run,059h,3A,2
CUSTOM alex_kidd_high_tech_world,04BAh,7E,2
CUSTOM black_belt,0A2h,3A,2
CUSTOM bonanza_bros,0B7Bh,7E,2
CUSTOM chase_hq,04B8h,BE,2
CUSTOM choplifter,0481h,3A,2
CUSTOM cyber_shinobi,0D8h,3A,2
CUSTOM cyborg_hunter,04Ch,3A,2
CUSTOM desert_strike,04EE4h,3A,2
CUSTOM dynamite_duke,0918h,7E,2
CUSTOM dynamite_dux,0D2h,3A,2
CUSTOM enduro_racer,011Fh,3A,2
CUSTOM e_swat,03CDh,3A,2
CUSTOM great_football,0192h,3A,2
CUSTOM ghostbusters,07CBh,BE,2
CUSTOM golden_axe_warrior,0BADh,3A,2
CUSTOM great_golf,0A9h,3A,2
CUSTOM great_volley_ball,019Dh,3A,2
CUSTOM hokutonoken,0A1h,3A,2
CUSTOM the_terminator,05429h,3A,2
CUSTOM spiderman_vs_kingpin,0C3Bh,3A,2
CUSTOM vigilante,01CAAh,7E,2
CUSTOM star_wars,01530h,3A,2
CUSTOM rocky,0C2h,3A,2
CUSTOM kenseiden,04Ch,3A,2
CUSTOM the_jungle_book,05708h,3A,2
CUSTOM klax,025Bh,3A,2
CUSTOM kung_fu_kid,0111Dh,3A,2
CUSTOM my_hero,02897h,3A,2
CUSTOM the_new_zealand_story,078C6h,7E,2
CUSTOM paperboy,0534Bh,3A,2
CUSTOM predator_2,07988h,3A,2
CUSTOM sagaia,013Bh,C3,2
CUSTOM tri_formation,0380h,3A,2
CUSTOM time_soldier,0B6Eh,BE,2
CUSTOM world_class_leader_board,062Ch,3A,2
CUSTOM wrestle_mania,079BEh,3A,2
CUSTOM zillion,0531h,3A,2
CUSTOM world_grand_prix,0Eh,7E,2
CUSTOM winter_games_1994,069B9h,3A,2
CUSTOM aerial_assault,02Eh,3A,2
CUSTOM popeye_beach_volley_ball,03216h,3A,2
CUSTOM dick_tracy,085Eh,3A,2
CUSTOM gauntlet,05DCh,3A,2
CUSTOM speedball_2,02C89h,7E,2
CUSTOM mahjong_sengoku_jidai,0181h,3A,2
CUSTOM sonic_drift_2,02A2h,7E,2
CUSTOM robocop_3,0A57h,2A,2
CUSTOM quartet,0351h,7E,2
CUSTOM psychic_world_gg,0976h,7E,2
CUSTOM streets_of_rage,067E2h,3A,2
CUSTOM bart_vs_space_mutants,0950h,3A,2
CUSTOM ghost_house,0BBh,3A,2
CUSTOM blade_eagle_3d,0387h,3A,2
CUSTOM bank_panic,0A2h,3A,2
CUSTOM barcelona_92,0BEBh,3A,2
CUSTOM pro_wrestling,037D1h,7E,2
CUSTOM scramble_spirits,0115h,7E,2
CUSTOM shanghai,02F0Fh,7E,2
CUSTOM slap_shot,0341h,3A,2
CUSTOM chakan,0823h,3A,2
CUSTOM hang_on_2,013Fh,3A,2
CUSTOM fatal_fury_special,0BA9h,3A,2
CUSTOM the_little_mermaid,0685h,3A,2
CUSTOM alien_syndrome_gg,0308h,C3,2
CUSTOM dr_robotnik_mean_bean,033DEh,3A,2
CUSTOM battleship,02435h,3A,2
CUSTOM batman_forever,05F1h,3A,2
CUSTOM super_off_road,02344h,3A,2
CUSTOM legend_of_illusion,070Eh,7E,2
CUSTOM buster_ball,02Fh,3A,2
CUSTOM power_strike_2,0282h,3A,2
CUSTOM sonic_spinball,0562h,FB,2
CUSTOM super_space_invaders,0D7h,3A,2
CUSTOM sd_gundam,02Fh,3A,2
CUSTOM lucky_dime,0D9h,3A,2
CUSTOM sega_game_pack_4n1,0205h,7E,2
CUSTOM space_harrier_gg,059h,3A,2
CUSTOM gg_1007,03148h,3A,2
CUSTOM gear_stadium,0150h,3A,2
CUSTOM tama_olympic,05DCh,7E,2
CUSTOM ecco,06339h,3A,2
CUSTOM green_dog,0420h,FB,2
CUSTOM cheese_cat_astrophe,0325h,3A,2
CUSTOM fantasy_zone_gg,02E82h,FB,2
CUSTOM dead_angle,031h,3A,2
CUSTOM doraemon,06Dh,3A,2
CUSTOM the_berlin_wall,07Ah,7E,2
CUSTOM the_incredible_crash_dummies,01DBEh,FB,2
CUSTOM hao_pai,01B3h,7E,2
CUSTOM sokoban,02Fh,3A,2
CUSTOM shinobi_2_gg,075h,3A,2
CUSTOM skweek,072Fh,BE,2
CUSTOM super_monaco_gp,0159h,7E,2
CUSTOM strider_returns,04ADh,3A,2
CUSTOM talespin,03E5h,FB,2
CUSTOM in_the_wake_of_vampire,0BDh,7E,2
CUSTOM geraldinho,0178h,3A,2
CUSTOM champion_baseball,0B75h,2A,2
CUSTOM borderline,0507h,7E,2
CUSTOM champion_tennis,05C3h,2A,2
CUSTOM alex_kidd_in_the_lost_stars,0D1h,3A,2
CUSTOM poseidon_wars_3d,0F27h,3A,2
CUSTOM wagyan_land,028Dh,3A,2
CUSTOM global_gladiators_gg,03ABCh,7E,2
CUSTOM magic_knight_rayearth,080h,3A,2
CUSTOM magic_knight_rayearth_2,080h,3A,2
CUSTOM yu_yu_hakusho,0551h,3A,2
CUSTOM yu_yu_hakusho_2,0295h,3A,2
CUSTOM sonic_triple_trouble,0854h,7E,2
CUSTOM super_monaco_gp_2,0221h,7E,2
CUSTOM magical_world,0BDh,7E,2
CUSTOM ax_battler,09Bh,7E,2
CUSTOM primal_rage,014D4h,3A,2
CUSTOM asterix_secret_mission,0229h,3A,2
CUSTOM dr_robotnik_sms,03508h,3A,2
CUSTOM taz_in_escape_from_mars,02F7Bh,3A,2
CUSTOM phantasy_star_gaiden,0188Eh,BE,2
CUSTOM castle_of_illusion_jap,04Ch,3A,2
CUSTOM casino_games,0B81h,BE,2
CUSTOM phantasy_star_gaiden_english_1,0188Eh,BE,2
CUSTOM phantasy_star_gaiden_english_2,0188Eh,BE,2
CUSTOM power_strike_2_sms,03EFh,3A,2
CUSTOM alex_kidd_bmx_trial,012Ah,3A,2
CUSTOM phantasy_star_japanese,059h,3A,2
CUSTOM artillery_duel,08321h,3A,2
CUSTOM bcs_quest,0AA76h+1,CB7F,2
CUSTOM grogs_revenge,081E8h,BE,2
CUSTOM ken_uston_blackjack,0869Ah+1,CB7F,2
CUSTOM burgertime,0904Bh,3A,2
CUSTOM jungle_hunt,08A98h,3A,2
CUSTOM learning_with_leeper,0BD5Dh,3A,2
CUSTOM mountain_king,0804Fh+1,CB76,2
CUSTOM one_on_one,0A696h,BE,2
CUSTOM mickey_2_sms,046h,3A,2
CUSTOM beavis_butthead,01B0h,BE,2
CUSTOM captain_america,0392h,3A,2
CUSTOM ironman_xomanowar,03DBFh,BE,2
CUSTOM last_bible,0BDh,7E,2
CUSTOM last_bible_s,0BDh,7E,2
CUSTOM aleste_gg,0DCFh,3A,2
CUSTOM asterix_1,046h,3A,2
CUSTOM basketball_nightmare,04FEAh,3A,2
CUSTOM monica_2,0FEEh,3A,2
CUSTOM star_wars_sms,02C1h,3A,2
CUSTOM rygar,01F5h,CB46,2
CUSTOM rygar_am,01F5h,CB46,2
CUSTOM penguin_land_sms,0D4h,FB,2
CUSTOM penguin_land_jap,0D4h,FB,2
CUSTOM shadow_dancer,01EBCh,3A,2
CUSTOM rambo_3,059h,3A,2

CUSTOM2 lemmings,03F75h,03F97h,3A,2
CUSTOM2 columns,0204h,0210h,3A,2
CUSTOM2 cloud_master,094Dh,1AC9h,3A,2
CUSTOM2 captain_silver,08C5h,1453h,3A,2
CUSTOM2 hang_on,0Ch,034h,7E,2
CUSTOM2 power_rangers_movie,0403h,041Dh,7E,2
CUSTOM2 alien_storm,01E59h,01E3Bh,7E,2
CUSTOM2 aladdin,09BFh,09D6h,7E,2
CUSTOM2 columns_sms,0186h,0192h,3A,2
CUSTOM2 the_lion_king,014B4h,0356Fh,3A,2
CUSTOM2 street_fighter_2,03606h,0360Dh,3A,2

; --------

install_arcade_smash_hits:
install_mortal_kombat_1:
install_mortal_kombat_2:
install_robocop_vs_terminator:
install_sapo_xule:
install_psycho_fox:
install_spiderman_sinister_six:
install_rc_grand_prix:
install_hook:
install_phantasy_star_adventure:
install_f1_championship:
install_trivial_pursuit:
install_asterix_and_the_great_rescue:
install_championship_hockey:
install_ganbare_gorby:
install_mickey_ultimate_challenge:
install_ristar:
install_shining_force_3:
install_shining_force_2:
install_hyoukori_hyoutanjima:
install_charles_doty_frogs:
install_gp_rider:
install_krustys_fun_house:
install_mortal_kombat_1_gg:
install_pengo:
install_royal_stone:
install_terminator_2:
install_basic_level_3:
install_music_editor:
install_desert_speedtrap:
install_poker_face_paul_blackjack:
install_shadow_of_the_beast:
install_smash_tv:
install_poker_face_paul_poker:
install_basic_level_2:
install_shikinjoh:
        ret

install_girls_garden:
install_flicky:
install_lode_runner:
install_rozzeta_no_syouzou:
install_champion_golf:
install_congo_bongo:
install_flipper:
install_n_sub:
install_pacar:
install_pop_flamer:
install_safari_hunt:
install_safari_race:
install_sindbad_mystery:
install_star_jacker:
install_yamato:
install_monaco_gp:
install_orguss:
install_penguin_land_sg:
        mov     sg1000,1
        ret

install_antartic_adventure:
install_moonsweeper:
install_2010:
install_adams_music_box:
install_alcazar:
install_aquattack:
install_beamrider:
install_blockade_runner:
install_boulder_dash:
install_brain_strainers:
install_buck_rogers:
install_bump_n_jump:
install_cabbage_patch_kids:
install_cabbage_picture_show:
install_campaign_84:
install_segas_carnival:
install_centipede:
install_choplifter_col:
install_congo_bongo_col:
install_cosmic_avenger:
install_cosmo_fighter_2:
install_dam_busters:
install_decathlon:
install_defender:
install_destructor:
install_donkey_kong:
install_donkey_kong_alt:
install_donkey_kong_jr:
install_dragonfire:
install_dr_seuss:
install_dukes_of_hazzard:
install_evolution:
install_fathom:
install_flipper_col:
install_fortune_builder:
install_fraction_fever:
install_franctic_freddy:
install_frenzy:
install_frogger_col:
install_frontline:
install_galaxi:
install_gateway_to_apshai:
install_gorf:
install_grogs_revenge_alt:
install_gust_buster:
install_gyruss:
install_hero:
install_illusions:
install_james_bond:
install_jukebox:
install_jumpman_junior:
install_keystone_kapers:
install_lady_bug:
install_linking_logic:
install_looping:
install_miner_2049ER:
install_montezuma_revenge:
install_motocross_racer:
install_mousetrap:
install_mr_do:
install_nova_blast:
install_oils_well:
install_omega_race:
install_one_on_one:
install_pepper_ii:
install_pitfall:
install_pitfall_2:
install_pit_stop:
install_popeye:
install_quest_for_quintana_roo:
install_river_raid:
install_robin_hood:
install_roc_n_rope:
install_rocky_super_action_boxing:
install_rolloverture:
install_super_dk_junior:
install_sammy_lightfoot:
install_sector_alpha:
install_sewer_sam:
install_sir_lancelot:
install_slither:
install_slurpy:
install_smurf_pnp_workshop:
install_smurf_rescue:
install_space_fury:
install_space_panic:
install_spectron:
install_spy_hunter:
install_squish_em_sam:
install_star_trek:
install_star_wars_col:
install_subroc:
install_sa_baseball:
install_sa_football:
install_super_cobra:
install_super_controller_tester:
install_super_cross_force:
install_tarzan:
install_telly_turtle:
install_the_heist:
install_threshold:
install_time_pilot:
install_tomarc_tb:
install_tournament_tennis:
install_turbo:
install_tutankamon:
install_up_n_down:
install_venture:
install_victory:
install_war_games:
install_war_room:
install_wing_war:
install_zaxxon:
install_zenji:
install_q_bert:
install_q_bert_2:
install_tapper:
        mov     sg1000,1
        mov     coleco,1
        ret

install_sega_chess:
        mov     statusmask,0FFh
        ret

install_zool:
install_zool_gg:
        mov     eax,offset custom_zool
        mov     dword ptr [offset inportxx+0BFh*4],eax
        ret

install_global_gladiators:
install_cool_spot:
install_xenon_2:
install_out_run_gg:
install_xmen_gamesmaster_legacy:
install_xmen:
install_ys:
install_alien_3:
install_gunstar_heroes:
install_riddick_bowe_boxing:
install_surf_ninjas:
        mov     linebyline,1
        ret

install_impossible_mission:
        mov     linebyline,1
        mov     do_collision,1
        ret

install_rescue_mission:
install_gangster_town:
        mov     linebyline,1
        mov     palette_raster,1
        mov     lightgun,1
        ret

install_pop_breaker:
        mov     country,0FFh
        ret

install_evander_holyfield:
        mov     regesp,0CFFFh
        ret

install_ecco:        
        mov     regesp,0CFFFh
        mov     linebyline,1
        mov     do_collision,1
        mov     eax,offset custom_ecco
        mov     dword ptr [offset iset+03Ah*4],eax
        ret

install_halley_wars:
        mov     linebyline,1
        mov     palette_raster,1
        mov     lcdfilter,1
        ret

install_batman_robin:
        mov     linebyline,1
        mov     palette_raster,1
        mov     lcdfilter,1
        mov     do_collision,1
        ret

install_rambo_3:
        mov     linebyline,1
        mov     palette_raster,1
        mov     lightgun,1
        mov     lightgun_mask,BIT_4
        mov     eax,offset custom_rambo_3
        mov     dword ptr [offset iset+03Ah*4],eax
        ret

install_alex_kidd_bmx_trial:
        mov     pad_enabled,1
        mov     eax,offset custom_alex_kidd_bmx_trial
        mov     dword ptr [offset iset+03Ah*4],eax
        ret

install_rtype:        
        mov     eax,offset custom_rtype_patch1
        mov     dword ptr [offset iset+03Ah*4],eax
        mov     eax,offset custom_rtype_patch2
        mov     dword ptr [offset iset+0BEh*4],eax
        ret

install_ultima_4:        
        mov     eax,offset custom_ultima_4_patch1
        mov     dword ptr [offset iset+0BEh*4],eax
        mov     eax,offset custom_ultima_4_patch2
        mov     dword ptr [offset iset+07Eh*4],eax
        ret

install_rampage:        
        mov     eax,offset custom_rampage_patch1
        mov     dword ptr [offset iset+0FBh*4],eax
        mov     eax,offset custom_rampage_patch2
        mov     dword ptr [offset iset+03Ah*4],eax
        ret

install_astro_pitpot:        
        mov     eax,offset custom_astro_pitpot_patch1
        mov     dword ptr [offset iset+03Ah*4],eax
        mov     eax,offset custom_astro_pitpot_patch2
        mov     dword ptr [offset iset+07Eh*4],eax
        ret

install_prince_of_persia:
install_batman_returns:
        mov     imagetype,0
        ret

align 4
delay_counter   dd      50

INSTALL alex_kidd_miracle,iset,07Eh
INSTALL sonic_2,iset,07Eh
INSTALL daffy_duck,iset,03Ah
INSTALL power_rangers_movie,iset,07Eh
INSTALL phantasy_star,iset,03Ah
INSTALL phantasy_star_brazilian,iset,03Ah
INSTALL indiana_jones_crusade,iset,03Ah
INSTALL double_dragon,iset,07Eh
INSTALL wonder_boy_3,iset,03Ah
INSTALL monica_castelo_dragao,iset,03Ah
INSTALL sonic_chaos,iset,07Eh
INSTALL rastan,iset,0FBh
INSTALL bram_stoker_dracula,iset,03Ah
INSTALL rainbow_islands,iset,000h
INSTALL megaman,iset,0FBh
INSTALL wonder_boy_2,iset,03Ah
INSTALL alex_kidd_shinobi_world,iset,03Ah
INSTALL sonic_1_gg,isetFDCBxx,046h
INSTALL sonic_labyrinth,iset,03Ah
INSTALL sonic_and_tails_2,iset,07Eh
INSTALL power_strike,iset,03Ah
INSTALL samurai_spirits,iset,0FBh
INSTALL fantasy_zone,iset,03Ah
INSTALL fantasy_zone_2,iset,03Ah
INSTALL wonder_boy_1,iset,03Ah
INSTALL lemmings,iset,03Ah
INSTALL spiderman_xmen,iset,03Ah
INSTALL galaga_91,iset,03Ah
INSTALL the_ottifants,iset,03Ah
INSTALL lord_of_sword,iset,0FBh
INSTALL spellcaster,iset,03Ah
INSTALL afterburner,iset,03Ah
INSTALL tom_and_jerry,iset,07Eh
INSTALL super_tetris,iset,03Ah
INSTALL secret_commando,iset,03Ah
INSTALL the_ninja,iset,07Eh
INSTALL miracle_warriors,iset,07Eh
INSTALL shinobi,iset,03Ah
INSTALL thunder_blade,iset,03Ah
INSTALL golden_axe,iset,03Ah
INSTALL fantasy_zone_the_maze,iset,03Ah
INSTALL super_tennis,iset,03Ah
INSTALL bomber_raid,iset,03Ah
INSTALL sensible_soccer,iset,03Ah
INSTALL moonwalker,iset,07Eh
INSTALL strider,iset,03Ah
INSTALL final_bubble_bobble,iset,0C3h
INSTALL action_fighter,iset,03Ah
INSTALL astro_warrior,iset,07Eh
INSTALL aztec_adventure,iset,03Ah  
INSTALL alien_syndrome,iset,03Ah
INSTALL pacmania,iset,03Ah
INSTALL teddy_boy,iset,03Ah
INSTALL columns,iset,03Ah
INSTALL sailor_moon_s,iset,03Ah
INSTALL sonic_2_gg,iset,07Eh
INSTALL transbot,iset,03Ah
INSTALL marble_madness,iset,03Ah
INSTALL cloud_master,iset,03Ah
INSTALL captain_silver,iset,03Ah
INSTALL global_defense,iset,03Ah
INSTALL galaxy_force,iset,03Ah
INSTALL ghouls_n_ghosts,iset,07Eh
INSTALL parlour_games,iset,0BEh
INSTALL deep_duck_trouble,iset,07Eh
INSTALL hang_on,iset,07Eh
INSTALL psychic_world,iset,07Eh
INSTALL castle_of_illusion,iset,03Ah
INSTALL out_run,iset,03Ah
INSTALL alex_kidd_high_tech_world,iset,07Eh
INSTALL altered_beast,iset,03Ah
INSTALL black_belt,iset,03Ah
INSTALL bonanza_bros,iset,07Eh
INSTALL chase_hq,iset,0BEh
INSTALL choplifter,iset,03Ah
INSTALL cyber_shinobi,iset,03Ah
INSTALL cyborg_hunter,iset,03Ah
INSTALL desert_strike,iset,03Ah
INSTALL dynamite_duke,iset,07Eh
INSTALL dynamite_dux,iset,03Ah
INSTALL enduro_racer,iset,03Ah
INSTALL e_swat,iset,03Ah
INSTALL great_football,iset,03Ah
INSTALL ghostbusters,iset,0BEh
INSTALL golden_axe_warrior,iset,03Ah
INSTALL great_golf,iset,03Ah
INSTALL great_volley_ball,iset,03Ah
INSTALL hokutonoken,iset,03Ah
INSTALL the_terminator,iset,03Ah
INSTALL spiderman_vs_kingpin,iset,03Ah
INSTALL vigilante,iset,07Eh
INSTALL alien_storm,iset,07Eh
INSTALL star_wars,iset,03Ah
INSTALL rocky,iset,03Ah
INSTALL kenseiden,iset,03Ah
INSTALL the_jungle_book,iset,03Ah
INSTALL klax,iset,03Ah
INSTALL kung_fu_kid,iset,03Ah
INSTALL my_hero,iset,03Ah
INSTALL the_new_zealand_story,iset,07Eh
INSTALL paperboy,iset,03Ah
INSTALL predator_2,iset,03Ah
INSTALL sagaia,iset,0C3h
INSTALL tri_formation,iset,03Ah
INSTALL time_soldier,iset,0BEh
INSTALL world_class_leader_board,iset,03Ah
INSTALL wrestle_mania,iset,03Ah
INSTALL zillion,iset,03Ah
INSTALL world_grand_prix,iset,07Eh
INSTALL winter_games_1994,iset,03Ah
INSTALL aerial_assault,iset,03Ah
INSTALL popeye_beach_volley_ball,iset,03Ah
INSTALL aladdin,iset,07Eh
INSTALL dick_tracy,iset,03Ah
INSTALL mahjong_sengoku_jidai,iset,03Ah
INSTALL psychic_world_gg,iset,07Eh
INSTALL streets_of_rage,iset,03Ah
INSTALL bank_panic,iset,03Ah
INSTALL barcelona_92,iset,03Ah
INSTALL pro_wrestling,iset,07Eh
INSTALL scramble_spirits,iset,07Eh
INSTALL shanghai,iset,07Eh
INSTALL slap_shot,iset,03Ah
INSTALL fatal_fury_special,iset,03Ah
INSTALL the_little_mermaid,iset,03Ah
INSTALL alien_syndrome_gg,iset,0C3h
INSTALL dr_robotnik_mean_bean,iset,03Ah
INSTALL battleship,iset,03Ah
INSTALL columns_sms,iset,03Ah
INSTALL legend_of_illusion,iset,07Eh
INSTALL buster_ball,iset,03Ah
INSTALL sonic_spinball,iset,0FBh
INSTALL super_space_invaders,iset,03Ah
INSTALL sonic_drift_2,iset,07Eh
INSTALL chakan,iset,03Ah
INSTALL batman_forever,iset,03Ah
INSTALL sd_gundam,iset,03Ah
INSTALL lucky_dime,iset,03Ah
INSTALL sega_game_pack_4n1,iset,07Eh
INSTALL space_harrier_gg,iset,03Ah
INSTALL gg_1007,iset,03Ah
INSTALL gear_stadium,iset,03Ah
INSTALL tama_olympic,iset,07Eh
INSTALL dead_angle,iset,03Ah
INSTALL doraemon,iset,03Ah
INSTALL the_incredible_crash_dummies,iset,0FBH
INSTALL hao_pai,iset,07Eh
INSTALL sokoban,iset,03Ah
INSTALL the_lion_king,iset,03Ah
INSTALL shinobi_2_gg,iset,03Ah
INSTALL skweek,iset,0BEh
INSTALL super_monaco_gp,iset,07Eh
INSTALL strider_returns,iset,03Ah
INSTALL geraldinho,iset,03Ah
INSTALL ghost_house,iset,03Ah
INSTALL wagyan_land,iset,03Ah
INSTALL magic_knight_rayearth,iset,03Ah
INSTALL magic_knight_rayearth_2,iset,03Ah
INSTALL yu_yu_hakusho,iset,03Ah
INSTALL yu_yu_hakusho_2,iset,03Ah
INSTALL sonic_triple_trouble,iset,07Eh
INSTALL magical_world,iset,07Eh
INSTALL ax_battler,iset,07Eh
INSTALL primal_rage,iset,03Ah
INSTALL asterix_secret_mission,iset,03Ah
INSTALL dr_robotnik_sms,iset,03Ah
INSTALL phantasy_star_gaiden,iset,0BEh
INSTALL castle_of_illusion_jap,iset,03Ah
INSTALL casino_games,iset,0BEh
INSTALL phantasy_star_gaiden_english_1,iset,0BEh
INSTALL phantasy_star_gaiden_english_2,iset,0BEh
INSTALL phantasy_star_japanese,iset,03Ah
INSTALL mickey_2_sms,iset,03Ah
INSTALL beavis_butthead,iset,0BEh
INSTALL captain_america,iset,03Ah
INSTALL ironman_xomanowar,iset,0BEh
INSTALL last_bible,iset,07Eh
INSTALL last_bible_s,iset,07Eh
INSTALL aleste_gg,iset,03Ah
INSTALL asterix_1,iset,03Ah
INSTALL basketball_nightmare,iset,03Ah
INSTALL monica_2,iset,03Ah
INSTALL star_wars_sms,iset,03Ah
INSTALL street_fighter_2,iset,03Ah
INSTALL rygar,isetCBxx,046h
INSTALL rygar_am,isetCBxx,046h
INSTALL penguin_land_sms,iset,0FBh
INSTALL penguin_land_jap,iset,0FBh
INSTALL shadow_dancer,iset,03Ah

INSTALL_CACHE super_off_road,iset,03Ah
INSTALL_CACHE space_harrier_3d,iset,07Eh
INSTALL_CACHE zaxxon_3d,iset,03Ah
INSTALL_CACHE blade_eagle_3d,iset,03Ah
INSTALL_CACHE alex_kidd_in_the_lost_stars,iset,03Ah

INSTALL_LINE gauntlet,iset,03Ah
INSTALL_LINE speedball_2,iset,07Eh
INSTALL_LINE quartet,iset,07Eh
INSTALL_LINE robocop_3,iset,02Ah
INSTALL_LINE bart_vs_space_mutants,iset,03Ah
INSTALL_LINE golvellius,iset,03Ah
INSTALL_LINE power_strike_2,iset,03Ah
INSTALL_LINE outrun_europe,iset,03Ah
INSTALL_LINE the_berlin_wall,iset,07Eh
INSTALL_LINE poseidon_wars_3d,iset,03Ah
INSTALL_LINE global_gladiators_gg,iset,07Eh
INSTALL_LINE power_strike_2_sms,iset,03Ah

INSTALL_RASTER california_games,iset,07Eh
INSTALL_RASTER space_harrier,iset,03Ah
INSTALL_RASTER sonic_1,isetFDCBxx,046h

INSTALL_LCD super_monaco_gp_2,iset,07Eh

INSTALL_SPRITE green_dog,iset,0FBh
INSTALL_SPRITE cheese_cat_astrophe,iset,03Ah
INSTALL_SPRITE fantasy_zone_gg,iset,0FBh
INSTALL_SPRITE talespin,iset,0FBh
INSTALL_SPRITE in_the_wake_of_vampire,iset,07Eh
INSTALL_SPRITE taz_in_escape_from_mars,iset,03Ah

INSTALL_SG1000 ninja_princess,iset,07Eh
INSTALL_SG1000 hang_on_2,iset,03Ah
INSTALL_SG1000 champion_baseball,iset,02Ah
INSTALL_SG1000 borderline,iset,07Eh
INSTALL_SG1000 champion_tennis,iset,02Ah

INSTALL_COLECO bcs_quest,isetCBxx,07Fh
INSTALL_COLECO grogs_revenge,iset,0BEh
INSTALL_COLECO ken_uston_blackjack,isetCBxx,07Fh
INSTALL_COLECO burgertime,iset,03Ah
INSTALL_COLECO jungle_hunt,iset,03Ah
INSTALL_COLECO learning_with_leeper,iset,03Ah
INSTALL_COLECO mountain_king,iset,076h
INSTALL_COLECO artillery_duel,iset,03Ah

; --------

name_alex_kidd_miracle:
        db      'SMS Alex Kidd in Miracle World$'
        db      'None$'

name_sonic_2:
        db      'SMS Sonic the Hedgehog 2$'
        db      'None$'

name_sonic_1:
        db      'SMS Sonic the Hedgehog$'
        db      'None$'
                               
name_sonic_1_gg:
        db      'GG Sonic the Hedgehog$'
        db      'Voice is out of pitch.$'
                               
name_girls_garden:
        db      'SG1000 Girl''s Garden$'
        db      'None$'

name_rozzeta_no_syouzou:
        db      'SG1000 Rozzeta no Syouzou$'
        db      'None$'

name_daffy_duck:
        db      'GG Daffy Duck in Hollywood$'
        db      'None$'

name_power_rangers_movie:
        db      'GG Power Rangers, the Movie$'
        db      'None$'

name_phantasy_star:
        db      'SMS Phantasy Star$'
        db      'None$'

name_phantasy_star_brazilian:
        db      'SMS Phantasy Star (brazilian version)$'
        db      'None$'

name_indiana_jones_crusade:
        db      'GG Indiana Jones and the Last Crusade$'
        db      'None$'

name_arcade_smash_hits:
        db      'SMS Arcade Smash Hits$'
        db      'None$'

name_mortal_kombat_1:
        db      'SMS Mortal Kombat$'
        db      'None$'

name_mortal_kombat_2:
        db      'SMS Mortal Kombat 2$'
        db      'None$'

name_robocop_vs_terminator:
        db      'SMS Robocop vs. Terminator$'
        db      'None$'

name_double_dragon:
        db      'SMS Double Dragon$'
        db      'None$'

name_wonder_boy_3:
        db      'SMS Wonder Boy 3$'
        db      'None$'

name_monica_castelo_dragao:
        db      'SMS Monica no Castelo do Dragao$'
        db      'None$'

name_sapo_xule:
        db      'SMS Sapo Xule$'
        db      'None$'

name_sonic_chaos:
        db      'SMS Sonic Chaos$'
        db      'None$'

name_hook:
        db      'SMS Hook$'
        db      'None$'

name_rastan:
        db      'SMS Rastan$'
        db      'None$'

name_rtype:
        db      'SMS R-Type$'
        db      'None$'

name_bram_stoker_dracula:
        db      'SMS Bram Stoker''s Dracula$'
        db      'None$'

name_rainbow_islands:
        db      'SMS Rainbow Islands$'
        db      'None$'

name_megaman:
        db      'GG Megaman$'
        db      'None$'

name_prince_of_persia:
        db      'SMS Prince of Persia$'
        db      'None$'

name_wonder_boy_2:
        db      'SMS Wonder Boy 2$'
        db      'None$'

name_wonder_boy_1:
        db      'SMS Wonder Boy$'
        db      'None$'

name_alex_kidd_shinobi_world:
        db      'SMS Alex Kidd in Shinobi World$'
        db      'None$'

name_sonic_labyrinth:
        db      'GG Sonic Labyrinth$'
        db      'None$'

name_sonic_and_tails_2:
        db      'GG Sonic and Tails 2$'
        db      'None, however a 15-bit color mode is required.$'

name_psycho_fox:
        db      'SMS Psycho Fox$'
        db      'None$'

name_outrun_europe:
        db      'SMS Out Run Europe$'
        db      'None$'

name_golvellius:
        db      'SMS Golvellius$'
        db      'None$'

name_power_strike:
        db      'SMS Power Strike / Aleste$'
        db      'None$'

name_samurai_spirits:
        db      'GG Samurai Spirits$'
        db      'None$'

name_fantasy_zone:
        db      'SMS Fantasy Zone$'
        db      'None$'

name_fantasy_zone_2:
        db      'SMS Fantasy Zone 2$'
        db      'None$'

name_lemmings:
        db      'SMS Lemmings$'
        db      'None$'

name_spiderman_xmen:
        db      'GG Spiderman and X-Men: Arcade''s Revenge$'
        db      'None$'

name_galaga_91:
        db      'GG Galaga 91$'
        db      'None$'

name_spiderman_sinister_six:
        db      'GG Spiderman: Return of Sinister Six$'
        db      'None$'

name_the_ottifants:
        db      'SMS The Ottifants$'
        db      'None$'

name_rc_grand_prix:
        db      'SMS R.C. Grand Prix$'
        db      'None$'

name_lord_of_sword:
        db      'SMS Lord of the Sword$'
        db      'None$'

name_rampage:
        db      'SMS Rampage$'
        db      'None$'

name_zaxxon_3d:
        db      'SMS Zaxxon 3D$'
        db      'None$'

name_space_harrier_3d:
        db      'SMS Space Harrier 3D$'
        db      'None$'

name_spellcaster:
        db      'SMS Spellcaster$'
        db      'None$'

name_afterburner:
        db      'SMS Afterburner$'
        db      'None$'

name_tom_and_jerry:
        db      'SMS Tom and Jerry, the Movie$'
        db      'None$'

name_super_tetris:
        db      'SMS Super Tetris$'
        db      'None$'

name_secret_commando:
        db      'SMS Secret Commando$'
        db      'None$'

name_the_ninja:
        db      'SMS The Ninja$'
        db      'None$'

name_miracle_warriors:
        db      'SMS Miracle Warriors$'
        db      'None$'

name_shinobi:
        db      'SMS Shinobi$'
        db      'None$'

name_thunder_blade:
        db      'SMS Thunder Blade$'
        db      'None$'

name_golden_axe:
        db      'SMS Golden Axe$'
        db      'None$'

name_space_harrier:
        db      'SMS Space Harrier$'
        db      'None$'

name_fantasy_zone_the_maze:
        db      'SMS Fantasy Zone, the Maze$'
        db      'None$'

name_super_tennis:
        db      'SMS Super Tennis$'
        db      'None$'

name_bomber_raid:
        db      'SMS Bomber Raid$'
        db      'None$'

name_sensible_soccer:
        db      'SMS Sensible Soccer$'
        db      'None$'

name_moonwalker:
        db      'SMS Moonwalker$'
        db      'None$'

name_strider:
        db      'SMS Strider$'
        db      'None$'

name_ultima_4:
        db      'SMS Ultima 4$'
        db      'None$'

name_final_bubble_bobble:
        db      'SMS Final Bubble Bobble$'
        db      'None$'

name_action_fighter:
        db      'SMS Action Fighter$'
        db      'None$'

name_astro_warrior:
        db      'SMS Astro Warrior$'
        db      'None$'

name_astro_pitpot:
        db      'SMS Astro Warrior / Pit Pot$'
        db      'None$'

name_aztec_adventure:
        db      'SMS Aztec Adventure$'
        db      'None$'

name_alien_syndrome:
        db      'SMS Alien Syndrome$'
        db      'None$'

name_pacmania:
        db      'SMS Pacmania$'
        db      'None$'

name_teddy_boy:
        db      'SMS Teddy Boy$'
        db      'None$'

name_columns:
        db      'GG Columns$'
        db      'None$'

name_sailor_moon_s:
        db      'GG Sailor Moon S$'
        db      'None$'

name_ninja_princess:
        db      'SG1000 Ninja Princess$'
        db      'None$'

name_sonic_2_gg:
        db      'GG Sonic the Hedgehog 2$'
        db      'Voice is out of pitch.$'

name_phantasy_star_adventure:
        db      'GG Phantasy Star Adventure$'
        db      'None$'

name_transbot:
        db      'SMS Transbot$'
        db      'None$'

name_marble_madness:
        db      'SMS Marble Madness$'
        db      'None$'

name_cloud_master:
        db      'SMS Cloud Master$'
        db      'None$'

name_captain_silver:
        db      'SMS Captain Silver$'
        db      'None$'

name_global_defense:
        db      'SMS Global Defense$'
        db      'None$'

name_galaxy_force:
        db      'SMS Galaxy Force$'
        db      'None$'

name_ghouls_n_ghosts:
        db      'SMS Ghouls''n''Ghosts$'
        db      'None$'

name_parlour_games:
        db      'SMS Parlour Games$'
        db      'None$'

name_deep_duck_trouble:
        db      'GG Deep Duck Trouble$'
        db      'None$'

name_out_run:
        db      'SMS Out Run$'
        db      'None$'

name_hang_on:
        db      'SMS Hang On$'
        db      'None$'

name_psychic_world:
        db      'SMS Psychic World$'
        db      'Intro is too slow.$'

name_castle_of_illusion:
        db      'SMS Castle of Illusion$'
        db      'None$'

name_california_games:
        db      'SMS California Games$'
        db      'None$'

name_alex_kidd_high_tech_world:
        db      'SMS Alex Kidd in High Tech World$'
        db      'None$'

name_altered_beast:
        db      'SMS Altered Beast$'
        db      'None$'

name_black_belt:
        db      'SMS Black Belt$'
        db      'None$'

name_bonanza_bros:
        db      'SMS Bonanza Bros.$'
        db      'None$'

name_chase_hq:
        db      'SMS Chase HQ$'
        db      'None$'

name_choplifter:
        db      'SMS Choplifter$'
        db      'None$'

name_cyber_shinobi:
        db      'SMS Cyber Shinobi$'
        db      'None$'

name_cyborg_hunter:
        db      'SMS Cyborg Hunter$'
        db      'None$'

name_desert_strike:
        db      'SMS Desert Strike$'
        db      'None$'

name_dynamite_duke:
        db      'SMS Dynamite Duke$'
        db      'None$'

name_dynamite_dux:
        db      'SMS Dynamite Dux$'
        db      'None$'

name_enduro_racer:
        db      'SMS Enduro Racer$'
        db      'None$'

name_e_swat:
        db      'SMS E-Swat$'
        db      'None$'

name_f1_championship:
        db      'SMS F1 Championship$'
        db      'None$'

name_great_football:
        db      'SMS Great Football$'
        db      'None$'

name_ghostbusters:
        db      'SMS Ghostbusters$'
        db      'None$'

name_golden_axe_warrior:
        db      'SMS Golden Axe Warrior$'
        db      'None$'

name_great_golf:
        db      'SMS Great Golf$'
        db      'None$'

name_great_volley_ball:
        db      'SMS Great Volley Ball$'
        db      'None$'

name_hokutonoken:
        db      'SMS Hokutonoken$'
        db      'None$'

name_impossible_mission:
        db      'SMS Impossible Mission$'
        db      'None$'

name_the_terminator:
        db      'SMS The Terminator$'
        db      'None$'

name_spiderman_vs_kingpin:
        db      'SMS Spiderman vs. the Kingpin$'
        db      'None$'

name_vigilante:
        db      'SMS Vigilante$'
        db      'None$'

name_alien_storm:
        db      'SMS Alien Storm$'
        db      'None$'

name_star_wars:
        db      'GG Star Wars$'
        db      'None$'

name_rocky:
        db      'SMS Rocky$'
        db      'None$'

name_kenseiden:
        db      'SMS Kenseiden$'
        db      'None$'

name_the_jungle_book:
        db      'SMS The Jungle Book$'
        db      'None$'

name_klax:
        db      'SMS Klax$'
        db      'None$'

name_kung_fu_kid:
        db      'SMS Kung Fu Kid$'
        db      'None$'

name_my_hero:
        db      'SMS My Hero$'
        db      'None$'

name_the_new_zealand_story:
        db      'SMS The New Zealand Story$'
        db      'None$'

name_paperboy:
        db      'SMS Paperboy$'
        db      'None$'

name_predator_2:
        db      'SMS Predator 2$'
        db      'None$'

name_sagaia:
        db      'SMS Sagaia$'
        db      'Speed is wild, sometimes goes too fast and sometimes '
        db      'too slow.$'

name_tri_formation:
        db      'SMS Tri Formation$'
        db      'None$'

name_trivial_pursuit:
        db      'SMS Trivial Pursuit$'
        db      'None$'

name_time_soldier:
        db      'SMS Time Soldier$'
        db      'None$'

name_world_class_leader_board:
        db      'SMS World Class Leader Board$'
        db      'None$'

name_wrestle_mania:
        db      'SMS WWF Steel Cage Challenge$'
        db      'None$'

name_zillion:
        db      'SMS Zillion$'
        db      'None$'

name_world_grand_prix:
        db      'SMS World Grand Prix$'
        db      'None$'

name_winter_games_1994:
        db      'SMS Winter Games 1994$'
        db      'None$'

name_aerial_assault:
        db      'GG Aerial Assault$'
        db      'None$'

name_batman_returns:
        db      'GG Batman Returns$'
        db      'None$'

name_popeye_beach_volley_ball:
        db      'GG Popeye Beach Volley Ball$'
        db      'None$'

name_aladdin:
        db      'GG Aladdin$'
        db      'None$'

name_dick_tracy:
        db      'SMS Dick Tracy$'
        db      'None$'

name_global_gladiators:
        db      'SMS Global Gladiators$'
        db      'None$'

name_cool_spot:
        db      'SMS Cool Spot$'
        db      'None$'

name_xenon_2:
        db      'SMS Xenon 2$'
        db      'None$'

name_gauntlet:
        db      'SMS Gauntlet$'
        db      'None$'

name_speedball_2:
        db      'SMS Speedball 2$'
        db      'None$'

name_mahjong_sengoku_jidai:
        db      'SMS Mahjong Sengoku Jidai$'
        db      'None$'

name_out_run_gg:
        db      'GG Out Run$'
        db      'Not playable. Too slow.$'

name_sonic_drift_2:
        db      'GG Sonic Drift 2$'
        db      'None$'

name_robocop_3:
        db      'GG Robocop 3$'
        db      'Color mismatch in the Sega logo.$'

name_quartet:
        db      'SMS Quartet$'
        db      'None$'

name_psychic_world_gg:
        db      'GG Psychic World$'
        db      'Intro is too slow$'

name_ristar:
        db      'GG Ristar$'
        db      'None$'

name_streets_of_rage:
        db      'GG Streets of Rage$'
        db      'None$'

name_xmen_gamesmaster_legacy:
        db      'GG X-Men: Gamesmaster''s Legacy$'
        db      'None$'

name_bart_vs_space_mutants:
        db      'SMS Bart vs. Space Mutants$'
        db      'None$'

name_ghost_house:
        db      'SMS Ghost House$'
        db      'None$'

name_blade_eagle_3d:
        db      'SMS Blade Eagle 3D$'
        db      'None$'

name_asterix_and_the_great_rescue:
        db      'SMS Asterix and the Great Rescue$'
        db      'None$'

name_bank_panic:
        db      'SMS Bank Panic$'
        db      'None$'

name_barcelona_92:
        db      'SMS Barcelona''92$'
        db      'None$'

name_championship_hockey:
        db      'SMS Championship Hockey$'
        db      'None$'

name_pro_wrestling:
        db      'SMS Pro Wrestling$'
        db      'None$'

name_scramble_spirits:
        db      'SMS Scramble Spirits$'
        db      'None$'

name_shanghai:
        db      'SMS Shanghai$'
        db      'None$'

name_slap_shot:
        db      'SMS Slap Shot$'
        db      'None$'

name_chakan:
        db      'GG Chakan$'
        db      'None$'

name_alex_kidd_in_the_lost_stars:
        db      'SMS Alex Kidd in The Lost Stars$'
        db      'None$'

name_ys:
        db      'SMS Ys$'
        db      'None$'

name_hang_on_2:
        db      'SG1000 Hang On 2$'
        db      'None$'

name_fatal_fury_special:
        db      'GG Fatal Fury Special$'
        db      'None$'

name_the_little_mermaid:
        db      'GG The Little Mermaid$'
        db      'None$'

name_alien_3:
        db      'GG Alien 3$'
        db      'None$'

name_alien_syndrome_gg:
        db      'GG Alien Syndrome$'
        db      'None$'

name_dr_robotnik_mean_bean:
        db      'GG Dr. Robotnik''s Mean Bean Machine$'
        db      'None$'

name_battleship:
        db      'GG Battleship$'
        db      'None$'

name_batman_forever:
        db      'GG Batman Forever$'
        db      'None$'

name_columns_sms:
        db      'SMS Columns$'
        db      'None$'

name_super_off_road:
        db      'GG Super Off Road$'
        db      'None$'

name_ganbare_gorby:
        db      'GG Ganbare Gorby$'
        db      'None$'

name_legend_of_illusion:
        db      'GG Legend of Illusion$'
        db      'None$'

name_buster_ball:
        db      'GG Buster Ball$'
        db      'None$'

name_power_strike_2:
        db      'GG Power Strike 2$'
        db      'None, however a 15-bit color mode is required.$'

name_sonic_spinball:
        db      'GG Sonic Spinball$'
        db      'Bug in the parallax scroll of the intro.$'

name_super_space_invaders:
        db      'GG Super Space Invaders$'
        db      'None$'

name_mickey_ultimate_challenge:
        db      'GG Mickey''s Ultimate Challenge$'
        db      'None$'

name_sd_gundam:
        db      'GG SD Gundam$'
        db      'None$'

name_lucky_dime:
        db      'GG Lucky Dime$'
        db      'None$'

name_sega_game_pack_4n1:
        db      'GG Sega Game Pack 4 in 1$'
        db      'None$'

name_shining_force_3:
        db      'GG Shining Force 3$'
        db      'None$'

name_shining_force_2:
        db      'GG Shining Force 2$'
        db      'None$'

name_gangster_town:
        db      'SMS Gangster Town$'
        db      'None.$'

name_rescue_mission:
        db      'SMS Rescue Mission$'
        db      'Graphic bugs on the opening screen.$'

name_cheese_cat_astrophe:
        db      'SMS Cheese Cat-astrophe$'
        db      'None$'

name_zool:
        db      'SMS Zool$'
        db      'None$'

name_zool_gg:
        db      'GG Zool$'
        db      'None$'

name_shadow_of_the_beast:
        db      'SMS Shadow of the Beast$'
        db      'None$'

name_sega_chess:
        db      'SMS Sega Chess$'
        db      'None$'

name_fantasy_zone_gg:
        db      'GG Fantasy Zone Gear$'
        db      'None$'

name_green_dog:
        db      'GG Green Dog$'
        db      'None$'

name_ecco:
        db      'GG Ecco$'
        db      'None$'

name_taz_in_escape_from_mars:
        db      'GG Taz in Escape From Mars$'
        db      'None$'

name_ax_battler:
        db      'GG Ax Battler$'
        db      'None$'

name_smash_tv:
        db      'GG Smash TV$'
        db      'None$'

name_space_harrier_gg:
        db      'GG Space Harrier$'
        db      'None, however a 15-bit color mode is required.$'

name_primal_rage:
        db      'GG Primal Rage$'
        db      'None$'

name_shikinjoh:
        db      'GG Shikinjoh$'
        db      'None$'

name_gear_stadium:
        db      'GG Gear Stadium$'
        db      'None$'

name_hyoukori_hyoutanjima:
        db      'GG Hyoukori Hyoutanjima$'
        db      'None$'

name_tama_olympic:
        db      'GG Tama Olympic$'
        db      'None$'

name_flicky:
        db      'SG1000 Flicky$'
        db      'None$'

name_lode_runner:
        db      'SG1000 Lode Runner$'
        db      'None$'

name_champion_golf:
        db      'SG1000 Champion Golf$'
        db      'None$'

name_charles_doty_frogs:
        db      'GG Charles Doty''s Frogs (second release)$'
        db      'None$'

name_dead_angle:
        db      'SMS Dead Angle$'
        db      'None$'

name_doraemon:
        db      'GG Doreamon$'
        db      'None$'

name_xmen:
        db      'GG X-Men$'
        db      'None$'

name_the_berlin_wall:
        db      'GG The Berlin Wall$'
        db      'None$'

name_the_incredible_crash_dummies:
        db      'GG The Incredible Crash Dummies$'
        db      'None$'

name_hao_pai:
        db      'GG Hao Pai$'
        db      'None$'

name_sokoban:
        db      'GG Sokoban$'
        db      'None$'

name_gp_rider:
        db      'GG GP Rider$'
        db      'None$'

name_gunstar_heroes:
        db      'GG Gunstar Heroes$'
        db      'None$'

name_krustys_fun_house:
        db      'GG Krusty''s Fun House$'
        db      'None$'

name_the_lion_king:
        db      'GG The Lion King$'
        db      'None$'

name_mortal_kombat_1_gg:
        db      'GG Mortal Kombat$'
        db      'None$'

name_pengo:
        db      'GG Pengo$'
        db      'None$'

name_riddick_bowe_boxing:
        db      'GG Riddick Bowe Boxing$'
        db      'None$'

name_royal_stone:
        db      'GG Royal Stone$'
        db      'None$'

name_shinobi_2_gg:
        db      'GG Shinobi 2$'
        db      'None$'

name_skweek:
        db      'GG Skweek$'
        db      'None$'

name_super_monaco_gp:
        db      'GG Super Monaco GP$'
        db      'None$'

name_strider_returns:
        db      'GG Strider Returns$'
        db      'None$'

name_talespin:
        db      'GG Talespin$'
        db      'None$'

name_terminator_2:
        db      'GG Terminator 2$'
        db      'Some graphic bugs.$'

name_in_the_wake_of_vampire:
        db      'GG In the Wake of Vampire$'
        db      'None$'

name_geraldinho:
        db      'SMS Geraldinho$'
        db      'None$'

name_champion_baseball:
        db      'SG1000 Champion Baseball$'
        db      'None$'

name_borderline:
        db      'SG1000 Borderline$'
        db      'None$'

name_congo_bongo:
        db      'SG1000 Congo Bongo$'
        db      'None$'

name_flipper:
        db      'SG1000 Flipper$'
        db      'None$'

name_n_sub:
        db      'SG1000 N-Sub$'
        db      'None$'

name_pacar:
        db      'SG1000 Pacar$'
        db      'None$'

name_pop_flamer:
        db      'SG1000 Pop Flamer$'
        db      'None$'

name_safari_hunt:
        db      'SG1000 Safari Hunting$'
        db      'None$'

name_safari_race:
        db      'SG1000 Safari Race$'
        db      'None$'

name_sindbad_mystery:
        db      'SG1000 Sindbad Mystery$'
        db      'None$'

name_star_jacker:
        db      'SG1000 Star Jacker$'
        db      'None$'

name_champion_tennis:
        db      'SG1000 Champion Tennis$'
        db      'None$'

name_yamato:
        db      'SG1000 Yamato$'
        db      'None$'

name_monaco_gp:
        db      'SG1000 Monaco GP$'
        db      'None$'

name_poseidon_wars_3d:
        db      'SMS Poseidon Wars 3D$'
        db      'None$'

name_basic_level_3:
        db      'SC3000 BASIC Level 3$'
        db      'None$'

name_music_editor:
        db      'SC3000 Music Editor$'
        db      'None$'

name_wagyan_land:
        db      'GG Wagyan Land$'
        db      'None$'

name_pop_breaker:
        db      'GG Pop Breaker$'
        db      'None$'

name_evander_holyfield:
        db      'GG Evander Holyfield Boxing$'
        db      'None$'

name_global_gladiators_gg:
        db      'GG Global Gladiators$'
        db      'None$'

name_halley_wars:
        db      'GG Halley Wars$'
        db      'None, however a 15-bit color mode is required.$'

name_magic_knight_rayearth:
        db      'GG Magic Knight Rayearth$'
        db      'None$'

name_magic_knight_rayearth_2:
        db      'GG Magic Knight Rayearth 2$'
        db      'None$'

name_yu_yu_hakusho:
        db      'GG Yu Yu Hakusho$'
        db      'None$'

name_yu_yu_hakusho_2:
        db      'GG Yu Yu Hakusho 2$'
        db      'None$'

name_sonic_triple_trouble:
        db      'GG Sonic Triple Trouble$'
        db      'None, however a 15-bit color mode is required.$'

name_super_monaco_gp_2:
        db      'GG Super Monaco GP 2$'
        db      'None, however a 15-bit color mode is required.$'

name_desert_speedtrap:
        db      'GG Desert Speedtrap$'
        db      'None$'

name_magical_world:
        db      'GG Ronald in the Magical World$'
        db      'None$'

name_poker_face_paul_blackjack:
        db      'GG Poker Face Paul''s Blackjack$'
        db      'None$'

name_poker_face_paul_poker:
        db      'GG Poker Face Paul''s Poker$'
        db      'None$'

name_orguss:
        db      'SG1000 Orguss$'
        db      'None$'

name_asterix_secret_mission:
        db      'SMS Asterix and the Secret Mission$'
        db      'None$'

name_dr_robotnik_sms:
        db      'SMS Dr. Robotnik''s Mean Bean Machine$'
        db      'None$'

name_phantasy_star_gaiden:
        db      'GG Phantasy Star Gaiden$'
        db      'None$'

name_castle_of_illusion_jap:
        db      'SMS Castle of Illusion (japanese version)$'
        db      'None$'

name_casino_games:
        db      'SMS Cassino Games$'
        db      'None$'

name_surf_ninjas:
        db      'GG Surf Ninjas$'
        db      'None$'

name_phantasy_star_gaiden_english_1:
        db      'GG Phantasy Star Gaiden (english, small font)$'
        db      'None$'

name_phantasy_star_gaiden_english_2:
        db      'GG Phantasy Star Gaiden (english, large font)$'
        db      'None$'

name_power_strike_2_sms:
        db      'SMS Power Strike 2$'
        db      'Flickering in the intro.$'

name_basic_level_2:
        db      'SC3000 BASIC Level 2$'
        db      'None$'

name_alex_kidd_bmx_trial:
        db      'SMS Alex Kidd BMX Trial$'
        db      'None$'

name_phantasy_star_japanese:
        db      'SMS Phantasy Star (japanese version)$'
        db      'None$'

name_antartic_adventure:
        db      'CV Antartic Adventure$'
        db      'None$'

name_moonsweeper:
        db      'CV Moonsweeper$'
        db      'None$'

name_2010:
        db      'CV 2010: The Graphic Action Game$'
        db      'None$'

name_adams_music_box:
        db      'CV Adam''s Musicbox Demo$'
        db      'None$'

name_alcazar:
        db      'CV Alcazar$'
        db      'None$'

name_aquattack:
        db      'CV Aquattack$'
        db      'None$'

name_artillery_duel:
        db      'CV Artillery Duel$'
        db      'None$'

name_bcs_quest:
        db      'CV BC''s Quest$'
        db      'None$'

name_grogs_revenge:
        db      'CV Grog''s Revenge$'
        db      'None$'

name_beamrider:
        db      'CV Beamrider$'
        db      'None$'

name_ken_uston_blackjack:
        db      'CV Ken Uston Blackjack-Poker$'
        db      'None$'

name_blockade_runner:
        db      'CV Blockade Runner$'
        db      'None$'

name_boulder_dash:
        db      'CV Boulder Dash$'
        db      'None$'

name_brain_strainers:
        db      'CV Brain Strainers$'
        db      'None$'

name_buck_rogers:
        db      'CV Buck Rogers$'
        db      'Not playable. Lock after starting.$'

name_bump_n_jump:
        db      'CV Bump''n''Jump$'
        db      'Not playable. Strange lockups.$'

name_burgertime:
        db      'CV Burgertime$'
        db      'None$'

name_cabbage_patch_kids:
        db      'CV Cabbage Patch Kids$'
        db      'None$'

name_cabbage_picture_show:
        db      'CV Cabbage Patch Kids Picture Show$'
        db      'None$'

name_campaign_84:
        db      'CV Campaign''84$'
        db      'None$'

name_segas_carnival:
        db      'CV Sega''s Carnival$'
        db      'None$'

name_centipede:
        db      'CV Centipede$'
        db      'Not playable. Lock at selection screen.$'

name_choplifter_col:
        db      'CV Choplifter$'
        db      'None$'

name_congo_bongo_col:
        db      'CV Congo Bongo$'
        db      'None$'

name_cosmic_avenger:    
        db      'CV Cosmic Avenger$'
        db      'None$'

name_cosmo_fighter_2:
        db      'CV Marcel de Kogel''s Cosmo Fighter 2$'
        db      'None$'

name_dam_busters:
        db      'CV The Dam Busters$'
        db      'None$'

name_decathlon:
        db      'CV Decathlon$'
        db      'None$'

name_defender:
        db      'CV Defender$'
        db      'Not playable. Lock at selection screen.$'

name_destructor:
        db      'CV Destructor$'
        db      'Not playable. Lock at selection screen.$'

name_donkey_kong:
        db      'CV Donkey Kong$'
        db      'None$'

name_donkey_kong_alt:
        db      'CV Donkey Kong (alternate)$'
        db      'None$'

name_donkey_kong_jr:
        db      'CV Donkey Kong Jr.$'
        db      'None$'

name_dragonfire:
        db      'CV Dragonfire$'
        db      'Not playable. Lock in second stage.$'

name_dr_seuss:
        db      'CV Dr. Seuss''s Fix-up the Mix-up Puzzler$'
        db      'None$'

name_dukes_of_hazzard:
        db      'CV The Dukes of Hazzard$'
        db      'None$'

name_evolution:
        db      'CV Evolution$'
        db      'None$'

name_fathom:
        db      'CV Fathom$'
        db      'Not playable. Resets when starting.$'

name_flipper_col:
        db      'CV Flipper Slipper$'
        db      'None$'

name_fortune_builder:
        db      'CV Fortune Builder$'
        db      'None$'

name_fraction_fever:
        db      'CV Fraction Fever$'
        db      'None$'

name_franctic_freddy:
        db      'CV Frantic Freddy$'
        db      'None$'

name_frenzy:
        db      'CV Frenzy$'
        db      'None$'

name_frogger_col:
        db      'CV Frogger$'
        db      'None$'

name_frontline:
        db      'CV Frontline$'
        db      'None$'

name_galaxi:
        db      'CV Galaxi$'
        db      'Not playable. Lock at startup.$'

name_gateway_to_apshai:
        db      'CV Gateway to Apshai$'
        db      'None$'

name_gorf:
        db      'CV Gorf$'
        db      'None$'

name_grogs_revenge_alt:
        db      'CV Grog''s Revenge (alternate)$'
        db      'None$'

name_gust_buster:
        db      'CV Gust Busters$'
        db      'None$'

name_gyruss:
        db      'CV Gyruss$'
        db      'None$'

name_hero:
        db      'CV HERO$'
        db      'None$'

name_illusions:
        db      'CV Illusions$'
        db      'None$'

name_james_bond:
        db      'CV James Bond$'
        db      'None$'

name_jukebox:
        db      'CV Jukebox$'
        db      'None$'

name_jumpman_junior:
        db      'CV Jumpman Junior$'
        db      'None$'

name_jungle_hunt:
        db      'CV Jungle Hunt$'
        db      'None$'

name_keystone_kapers:
        db      'CV Keystone Kapers$'
        db      'None$'

name_lady_bug:
        db      'CV Lady Bug$'
        db      'None$'

name_learning_with_leeper:
        db      'CV Learning with Leeper$'
        db      'None$'

name_linking_logic:     
        db      'CV Linking Logic$'
        db      'None$'

name_looping:
        db      'CV Looping$'
        db      'None$'

name_miner_2049ER:
        db      'CV Miner 2049ER$'
        db      'None$'

name_montezuma_revenge:
        db      'CV Montezuma''s Revenge$'
        db      'Not playable. Lock at intro screen.$'

name_motocross_racer:
        db      'CV Motocross Racer$'
        db      'None$'

name_mountain_king:
        db      'CV Mountain King$'
        db      'None$'

name_mousetrap:
        db      'CV Mousetrap$'
        db      'Not playable. Reset before starting.$'

name_mr_do:
        db      'CV Mr. Do!$'
        db      'None$'

name_nova_blast:
        db      'CV Nova Blast$'
        db      'None$'

name_oils_well:
        db      'CV Oil''s Well$'
        db      'None$'

name_omega_race:
        db      'CV Omega Race$'
        db      'None$'

name_one_on_one:
        db      'CV One on One$'
        db      'None$'

name_pepper_ii:
        db      'CV Pepper II$'
        db      'None$'

name_pitfall:
        db      'CV Pitfall$'
        db      'None$'

name_pitfall_2:
        db      'CV Pitfall 2$'
        db      'Not playable. Player can''t get items.$'

name_pit_stop:
        db      'CV Pit Stop$'
        db      'Not playable. Crash after starting.$'

name_popeye:
        db      'CV Popeye$'
        db      'Not playable. Player can''t get items.$'

name_q_bert:
        db      'CV Q-Bert$'
        db      'Not playable. Enemies can''t hit player.$'

name_q_bert_2:
        db      'CV Q-Bert 2$'
        db      'Not playable. Enemies can''t hit player + graphic bugs.$'

name_quest_for_quintana_roo:
        db      'CV Quest for Quintana Roo$'
        db      'None$'

name_river_raid:
        db      'CV River Raid$'
        db      'None$'

name_robin_hood:
        db      'CV Robin Hood$'
        db      'None$'

name_roc_n_rope:
        db      'CV Roc''n''Rope$'
        db      'None$'

name_rocky_super_action_boxing:
        db      'CV Rocky Super-Action Boxing$'
        db      'None$'

name_rolloverture:
        db      'CV Rolloverture$'
        db      'None$'

name_super_dk_junior:
        db      'CV Super Donkey Kong Junior$'
        db      'None$'

name_sammy_lightfoot:
        db      'CV Sammy Lightfoot$'
        db      'None$'

name_sector_alpha:
        db      'CV Sector Alpha$'
        db      'None$'

name_sewer_sam:
        db      'CV Sewer Sam$'
        db      'Not playable. Lock at intro screen.$'

name_sir_lancelot:
        db      'CV Sir Lancelot$'
        db      'Not playable. Enemies can''t hit player.$'

name_slither:
        db      'CV Slither$'
        db      'None$'

name_slurpy:
        db      'CV Slurpy$'
        db      'None$'

name_smurf_pnp_workshop:
        db      'CV Smurf Paint''n''Play Workshop$'
        db      'None$'

name_smurf_rescue:
        db      'CV Smurf Rescue$'
        db      'None$'

name_space_fury:
        db      'CV Space Fury$'
        db      'None$'

name_space_panic:
        db      'CV Space Panic$'
        db      'None$'

name_spectron:
        db      'CV Spectron$'
        db      'None$'

name_spy_hunter:
        db      'CV Spy Hunter$'
        db      'None$'

name_squish_em_sam:
        db      'CV Squish''em Sam!$'
        db      'Not playable. Enemies can''t hit player.$'

name_star_trek:
        db      'CV Star Trek$'
        db      'None$'

name_star_wars_col:
        db      'CV Star Wars$'
        db      'None$'

name_subroc:
        db      'CV Subroc$'
        db      'None$'

name_sa_baseball:
        db      'CV Super Action Baseball$'
        db      'None$'

name_sa_football:
        db      'CV Super Action Football$'
        db      'None$'

name_super_cobra:
        db      'CV Super Cobra$'
        db      'Not playable. Graphic bugs.$'

name_super_controller_tester:
        db      'CV Super Controller Tester$'
        db      'Not playable. Graphic bugs.$'

name_super_cross_force:
        db      'CV Super Cross Force$'
        db      'None$'

name_tapper:
        db      'CV Tapper$'
        db      'None$'

name_tarzan:
        db      'CV Tarzan$'
        db      'None$'

name_telly_turtle:
        db      'CV Telly Turtle$'
        db      'None$'

name_the_heist:
        db      'CV The Heist$'
        db      'None$'

name_threshold:
        db      'CV Threshold$'
        db      'None$'

name_time_pilot:
        db      'CV Time Pilot$'
        db      'None$'

name_tomarc_tb:
        db      'CV Tomarc the Barbarian$'
        db      'None$'

name_tournament_tennis:
        db      'CV Tournament Tennis$'
        db      'None$'

name_turbo:
        db      'CV Turbo$'
        db      'Not playable. Lock at selection screen.$'

name_tutankamon:
        db      'CV Tutankamon$'
        db      'Not playable. Crash at startup.$'

name_up_n_down:
        db      'CV Up''n''Down$'
        db      'None$'

name_venture:
        db      'CV Venture$'
        db      'None$'

name_victory:
        db      'CV Victory$'
        db      'None$'

name_war_games:
        db      'CV War Games$'
        db      'None$'

name_war_room:
        db      'CV War Room$'
        db      'None$'

name_wing_war:
        db      'CV Wing War$'
        db      'None$'

name_zaxxon:
        db      'CV Zaxxon$'
        db      'None$'

name_zenji:
        db      'CV Zenji$'
        db      'None$'

name_mickey_2_sms:
        db      'SMS Land of Illusion$'
        db      'None$'

name_beavis_butthead:
        db      'GG Beavis and Butthead$'
        db      'None$'

name_captain_america:
        db      'GG Captain America and the Avengers$'
        db      'None$'

name_ironman_xomanowar:
        db      'GG Iron Man and X-O Manowar in Heavy Metal$'
        db      'None$'

name_last_bible:
        db      'GG Last Bible$'
        db      'None$'

name_last_bible_s:
        db      'GG Last Bible S$'
        db      'None$'

name_aleste_gg:
        db      'GG Aleste$'
        db      'None$'

name_asterix_1:
        db      'SMS Asterix$'
        db      'None$'

name_batman_robin:
        db      'GG Adventures of Batman and Robin$'
        db      'None, however a 15-bit color mode is required.$'

name_basketball_nightmare:
        db      'SMS Basket Ball Nightmare$'
        db      'None$'

name_monica_2:
        db      'SMS Turma da Monica em O Resgate$'
        db      'None$'

name_star_wars_sms:
        db      'SMS Star Wars$'
        db      'None$'

name_street_fighter_2:
        db      'SMS Street Fighter 2''$'
        db      'None$'

name_rygar:
        db      'SMS Rygar (japanese version)$'
        db      'None$'

name_rygar_am:
        db      'SMS Rygar$'
        db      'None$'

name_penguin_land_sms:
        db      'SMS Penguin Land$'
        db      'None$'

name_penguin_land_jap:
        db      'SMS Penguin Land (japanese version)$'
        db      'None$'

name_shadow_dancer:
        db      'SMS Shadow Dancer$'
        db      'None$'

name_penguin_land_sg:
        db      'SG1000 Penguin Land$'
        db      'None$'

name_rambo_3:
        db      'SMS Rambo 3$'
        db      'None$'

; --------

guess_table:

        ; GUESS SMS

        GUESS   07CE14CB3h,action_fighter
        GUESS   0780CAE0Fh,afterburner
        GUESS   0B7D52DCFh,alex_kidd_bmx_trial
        GUESS   0C6F6E434h,alex_kidd_high_tech_world
        GUESS   0B86F21D8h,alex_kidd_in_the_lost_stars
        GUESS   020E6175Eh,alex_kidd_miracle
        GUESS   093FEE620h,alex_kidd_shinobi_world
        GUESS   0FB957242h,alien_storm
        GUESS   0499B89B3h,alien_syndrome
        GUESS   0430E0FBBh,altered_beast
        GUESS   0CE49ED6Ah,arcade_smash_hits
        GUESS   092AFC665h,asterix_1
        GUESS   0A3A70ADCh,asterix_and_the_great_rescue
        GUESS   024F850ACh,asterix_secret_mission
        GUESS   06211A370h,astro_warrior
        GUESS   00A47B6C3h,astro_pitpot
        GUESS   02222443Ah,aztec_adventure
        GUESS   034944C3Dh,bank_panic
        GUESS   0C786BB81h,barcelona_92
        GUESS   0E839A33Dh,bart_vs_space_mutants
        GUESS   051BD1174h,basketball_nightmare
        GUESS   02DE32DC7h,black_belt
        GUESS   002D14D00h,blade_eagle_3d
        GUESS   01DE93E34h,bomber_raid
        GUESS   06B0389C9h,bonanza_bros
        GUESS   05CD57D60h,bram_stoker_dracula
        GUESS   04EC19EFCh,california_games
        GUESS   0F804C07Ah,captain_silver
        GUESS   086DF49F0h,casino_games
        GUESS   00ED68E95h,castle_of_illusion
        GUESS   095EE1087h,castle_of_illusion_jap
        GUESS   0EB715E18h,championship_hockey
        GUESS   061446BDCh,chase_hq
        GUESS   06D484483h,cheese_cat_astrophe
        GUESS   017107012h,choplifter
        GUESS   0EC18B368h,cloud_master
        GUESS   0F9EC2453h,columns_sms
        GUESS   069297A56h,cool_spot
        GUESS   07D3D9522h,cyber_shinobi
        GUESS   0CFDB5F2Eh,cyborg_hunter
        GUESS   0A35D418Ch,dead_angle
        GUESS   000DA6351h,desert_strike
        GUESS   0A22FE575h,dick_tracy
        GUESS   0985097F4h,double_dragon
        GUESS   09E426DC8h,dr_robotnik_sms
        GUESS   09063C98Eh,dynamite_duke
        GUESS   01E42A8E3h,dynamite_dux
        GUESS   009B23E6Ch,enduro_racer
        GUESS   05B294C72h,e_swat
        GUESS   0CC4E2E9Ah,f1_championship
        GUESS   0B797563Eh,fantasy_zone
        GUESS   058A9073Ch,fantasy_zone_2
        GUESS   0C3346F2Ah,fantasy_zone_the_maze
        GUESS   042FDFF15h,final_bubble_bobble
        GUESS   0E62C1855h,galaxy_force
        GUESS   066523B98h,gangster_town
        GUESS   0D0004267h,gauntlet
        GUESS   085D9889Fh,geraldinho
        GUESS   0BF80350Dh,ghostbusters
        GUESS   01FEF63BDh,ghost_house
        GUESS   035E0DE97h,ghouls_n_ghosts
        GUESS   0045CFDF1h,global_defense
        GUESS   0CC308233h,global_gladiators
        GUESS   0F8EB0BB5h,golden_axe
        GUESS   0447E2161h,golden_axe_warrior
        GUESS   0CD122DC2h,golvellius
        GUESS   00E781502h,great_football
        GUESS   07ACF8005h,great_golf
        GUESS   0ACB3E803h,great_volley_ball
        GUESS   0EC8FB673h,hang_on
        GUESS   0A6A87146h,hokutonoken
        GUESS   03E57AA26h,hook
        GUESS   0B658F5F3h,impossible_mission
        GUESS   0E67635F9h,kenseiden
        GUESS   029624FE9h,klax
        GUESS   06935A99Eh,kung_fu_kid
        GUESS   07F1CD0D7h,mickey_2_sms
        GUESS   0C097EA38h,lemmings
        GUESS   049D90327h,lord_of_sword
        GUESS   08382EA60h,mahjong_sengoku_jidai
        GUESS   09E588DC8h,marble_madness
        GUESS   0548CA3A5h,miracle_warriors
        GUESS   0DC1D8A86h,monica_castelo_dragao
        GUESS   0FD203B5Bh,moonwalker
        GUESS   0B1AEE705h,mortal_kombat_1
        GUESS   02F5706F4h,mortal_kombat_2
        GUESS   0ED359553h,my_hero
        GUESS   09F72DE1Dh,out_run
        GUESS   00ED0A7D6h,outrun_europe
        GUESS   0B88F9751h,pacmania
        GUESS   0237C10D2h,paperboy
        GUESS   0A23FA25Fh,parlour_games
        GUESS   003109DA6h,penguin_land_sms
        GUESS   004E60F2Ah,penguin_land_jap
        GUESS   00617DA54h,phantasy_star
        GUESS   02D3AF5A5h,phantasy_star_brazilian
        GUESS   09D996FFCh,phantasy_star_japanese
        GUESS   0D7EA6F42h,power_strike
        GUESS   01C0ECD2Eh,power_strike_2_sms
        GUESS   0F71D678Eh,poseidon_wars_3d
        GUESS   04D94A6EEh,predator_2
        GUESS   062AAB2FBh,prince_of_persia
        GUESS   0FD55A212h,pro_wrestling
        GUESS   04630DE13h,psychic_world
        GUESS   0CDBC965Fh,psycho_fox
        GUESS   022DA901Fh,quartet
        GUESS   0B1FCB1AEh,rainbow_islands
        GUESS   08C2DA449h,rambo_3
        GUESS   0D363815Eh,rampage
        GUESS   0F718DAA8h,rastan
        GUESS   0759910F1h,rc_grand_prix
        GUESS   06A142230h,rescue_mission
        GUESS   00DD80A34h,robocop_vs_terminator
        GUESS   059129B59h,rocky
        GUESS   041A56A42h,rtype
        GUESS   03DC04410h,rygar_am
        GUESS   0CC05857Ch,rygar
        GUESS   0FB0E1EC8h,sagaia
        GUESS   0EFBDB180h,sapo_xule
        GUESS   06C817600h,secret_commando
        GUESS   08630A0E1h,sega_chess
        GUESS   048A2183Ah,sensible_soccer
        GUESS   085705477h,scramble_spirits
        GUESS   02CB75693h,shadow_dancer
        GUESS   01AB1BFDBh,shadow_of_the_beast
        GUESS   0C1065992h,shanghai
        GUESS   06AB79C51h,shinobi
        GUESS   052DCF566h,slap_shot
        GUESS   060B3B1E5h,sonic_chaos
        GUESS   078E76084h,sonic_1
        GUESS   0B9B0ED2Dh,sonic_2
        GUESS   03AA54A08h,space_harrier
        GUESS   0733C750Bh,space_harrier_3d
        GUESS   08436A316h,speedball_2
        GUESS   06BBC59DBh,spellcaster
        GUESS   052B2B233h,spiderman_vs_kingpin
        GUESS   09ECB7688h,star_wars_sms
        GUESS   0FA2772A5h,street_fighter_2
        GUESS   0B565AED7h,strider
        GUESS   0B71DD76Ch,super_tennis
        GUESS   0CA835F01h,super_tetris
        GUESS   067F898D1h,teddy_boy
        GUESS   0855FA9DCh,the_jungle_book
        GUESS   0F1025F09h,the_new_zealand_story
        GUESS   05172168Bh,the_ninja
        GUESS   076BC1F11h,the_ottifants
        GUESS   0C69F94DBh,the_terminator
        GUESS   028873BC9h,thunder_blade
        GUESS   0314D610Ah,time_soldier
        GUESS   0CE3796D7h,tom_and_jerry
        GUESS   020BB642Fh,transbot
        GUESS   07991B23Ch,tri_formation
        GUESS   0745ABC16h,trivial_pursuit
        GUESS   054453931h,monica_2
        GUESS   0DCCE0A8Ch,ultima_4
        GUESS   0F4017735h,vigilante
        GUESS   02EE1AEEAh,winter_games_1994
        GUESS   0C7BFCED5h,wonder_boy_1
        GUESS   08DF3F8E4h,wonder_boy_2
        GUESS   0A13E0639h,wonder_boy_3
        GUESS   017EFDD79h,world_class_leader_board
        GUESS   04D76A31Fh,world_grand_prix
        GUESS   00FCF351Bh,wrestle_mania
        GUESS   0AB171AE2h,xenon_2
        GUESS   0FCCC1B82h,ys
        GUESS   01F7F2299h,zaxxon_3d        
        GUESS   06191508Eh,zillion
        GUESS   0606BCF14h,zool

        ; GUESS GG

        GUESS   07BCD2D01h,batman_robin
        GUESS   0BC00E8C8h,aerial_assault
        GUESS   04016699Ch,aladdin
        GUESS   06D6FBE4Ah,aleste_gg
        GUESS   06E46B114h,alien_3
        GUESS   095CBC6EAh,alien_syndrome_gg
        GUESS   03466FD14h,ax_battler
        GUESS   0634F58F0h,batman_forever
        GUESS   0186290DAh,batman_returns
        GUESS   0D85F18D2h,battleship
        GUESS   0BEE65BEFh,beavis_butthead
        GUESS   0C5061158h,buster_ball
        GUESS   0E33EB8F0h,captain_america
        GUESS   0325B9A06h,chakan
        GUESS   0E1519494h,charles_doty_frogs
        GUESS   0D225CFABh,columns
        GUESS   0E06AD8E0h,daffy_duck
        GUESS   0909D0F23h,deep_duck_trouble
        GUESS   0367AEF09h,desert_speedtrap
        GUESS   04F799374h,doraemon
        GUESS   0BE45E9B8h,dr_robotnik_mean_bean
        GUESS   03D513DB5h,ecco
        GUESS   0739778DBh,evander_holyfield
        GUESS   09D68CD3Bh,fantasy_zone_gg
        GUESS   0A20E0B63h,fatal_fury_special
        GUESS   049D019A0h,galaga_91
        GUESS   0BF6E77CFh,ganbare_gorby
        GUESS   0ED06275Ah,gear_stadium
        GUESS   095AF40ADh,global_gladiators_gg
        GUESS   0FEB26621h,gp_rider
        GUESS   0ED3DEFACh,green_dog
        GUESS   0BBF88B6Fh,gunstar_heroes
        GUESS   0E49F87ECh,hao_pai
        GUESS   07822EC79h,halley_wars
        GUESS   0BB3B781Bh,hyoukori_hyoutanjima
        GUESS   00E89411Dh,indiana_jones_crusade
        GUESS   0E1EE5FC3h,in_the_wake_of_vampire
        GUESS   0329BFF2Bh,ironman_xomanowar
        GUESS   03A46922Bh,krustys_fun_house
        GUESS   082F6E339h,last_bible
        GUESS   01C6D45BDh,last_bible_s
        GUESS   0E4C296A2h,legend_of_illusion
        GUESS   0B9B4EE32h,lucky_dime
        GUESS   09350882Eh,magic_knight_rayearth
        GUESS   0F6C0F060h,magic_knight_rayearth_2
        GUESS   03E15E7B9h,megaman
        GUESS   057802217h,mickey_ultimate_challenge
        GUESS   019E59A73h,mortal_kombat_1_gg
        GUESS   0C0D53B72h,out_run_gg
        GUESS   0A24BCD03h,pengo
        GUESS   03C2740DEh,phantasy_star_adventure
        GUESS   0B2B9C604h,phantasy_star_gaiden
        GUESS   08049DCE3h,phantasy_star_gaiden_english_1
        GUESS   0AB19C9AEh,phantasy_star_gaiden_english_2
        GUESS   0BB88E268h,poker_face_paul_blackjack
        GUESS   09E80CDD5h,poker_face_paul_poker
        GUESS   09DC2345Eh,pop_breaker
        GUESS   0FBAE6CEEh,popeye_beach_volley_ball
        GUESS   0DB254C06h,power_rangers_movie
        GUESS   0AD13C491h,power_strike_2
        GUESS   03BF622C1h,primal_rage
        GUESS   0D41856CCh,psychic_world_gg
        GUESS   0D919FEDAh,riddick_bowe_boxing
        GUESS   001FC0962h,ristar
        GUESS   006970CB7h,robocop_3
        GUESS   082968600h,magical_world
        GUESS   06B13A517h,royal_stone
        GUESS   02A067E30h,sailor_moon_s
        GUESS   0CB511443h,samurai_spirits
        GUESS   0652123F0h,sd_gundam
        GUESS   0F502C85Ch,sega_game_pack_4n1
        GUESS   09934B784h,shikinjoh
        GUESS   00823CD03h,shining_force_2
        GUESS   0786F8730h,shining_force_3
        GUESS   0CEB50E7Eh,shinobi_2_gg
        GUESS   0EC0EEBE5h,skweek
        GUESS   01CDB1FBCh,smash_tv
        GUESS   064776BA5h,sokoban
        GUESS   05A7D97DAh,sonic_and_tails_2
        GUESS   002FA73BCh,sonic_drift_2
        GUESS   0F185B514h,sonic_labyrinth
        GUESS   06FA2D9BBh,sonic_1_gg        
        GUESS   0F3CC84AEh,sonic_2_gg
        GUESS   0D0571B16h,sonic_triple_trouble
        GUESS   09B068E85h,sonic_spinball
        GUESS   06439F6EFh,space_harrier_gg
        GUESS   01E06D410h,spiderman_sinister_six
        GUESS   0013B7E9Eh,spiderman_xmen
        GUESS   0F5F061D9h,star_wars
        GUESS   083E92D52h,streets_of_rage
        GUESS   0F05C57DFh,strider_returns
        GUESS   0DCCEBBF0h,super_off_road
        GUESS   0ED2A76E0h,super_monaco_gp
        GUESS   0503DC316h,super_monaco_gp_2
        GUESS   007FC5E56h,super_space_invaders
        GUESS   07A9FF1A3h,surf_ninjas
        GUESS   09241092Dh,talespin
        GUESS   0C0097193h,tama_olympic
        GUESS   08F9A798Fh,taz_in_escape_from_mars
        GUESS   0ACF087EAh,terminator_2
        GUESS   013147B98h,the_berlin_wall
        GUESS   08239841Eh,the_incredible_crash_dummies    
        GUESS   0E33CBC21h,the_lion_king
        GUESS   0FE2218A2h,the_little_mermaid
        GUESS   0AE41B877h,wagyan_land
        GUESS   0A24537EDh,xmen
        GUESS   00C2A85F4h,xmen_gamesmaster_legacy
        GUESS   0480A90C7h,yu_yu_hakusho
        GUESS   040054E6Ch,yu_yu_hakusho_2
        GUESS   0D3947A25h,zool_gg
        ;GUESS   09934B784h,gg_1007

        ; GUESS SG1000

        GUESS   0D2A7ECB0h,borderline
        GUESS   074FFC46Bh,champion_baseball
        GUESS   0DDAD4C48h,champion_golf
        GUESS   099F5DBAFh,champion_tennis
        GUESS   0EF81C46Dh,congo_bongo
        GUESS   069FF6D43h,flicky
        GUESS   0C1AE45F6h,flipper
        GUESS   0EC2B3C57h,girls_garden
        GUESS   01DACF2A6h,hang_on_2
        GUESS   01F18F4B0h,lode_runner
        GUESS   046147010h,monaco_gp
        GUESS   0BA8C894Eh,ninja_princess
        GUESS   01FB8A1F3h,n_sub
        GUESS   00A2B893Bh,orguss
        GUESS   039AB4216h,pacar
        GUESS   0B379B4ACh,penguin_land_sg
        GUESS   0B09FEE2Dh,pop_flamer
        GUESS   0E697F176h,rozzeta_no_syouzou
        GUESS   090A6EABAh,safari_hunt
        GUESS   00146DA3Ah,safari_race
        GUESS   072B3D47Dh,sindbad_mystery
        GUESS   029CE9C77h,star_jacker
        GUESS   030B2BC26h,yamato

        ; GUESS SC3000

        GUESS   0AC533E04h,basic_level_2
entry_basic:        
        GUESS   0C9976820h,basic_level_3
entry_music:        
        GUESS   07E2E6590h,music_editor

        ; GUESS CV

        GUESS   0A93CDCACh,2010
        GUESS   0DA2A08EDh,adams_music_box
        GUESS   0F753B30Fh,alcazar
        GUESS   01E267818h,antartic_adventure
        GUESS   06B784F6Ah,aquattack
        GUESS   0748574F0h,artillery_duel
        GUESS   0B4F8167Eh,bcs_quest
        GUESS   005CBDB58h,beamrider
        GUESS   0AE58D1AFh,blockade_runner
        GUESS   02FF43829h,boulder_dash
        GUESS   0F2D5E3E1h,brain_strainers
        GUESS   0DB43530Bh,buck_rogers
        GUESS   0257615F4h,bump_n_jump
        GUESS   06E291F92h,burgertime
        GUESS   0E146C1B1h,cabbage_patch_kids
        GUESS   0755727A3h,cabbage_picture_show
        GUESS   0AB533B60h,campaign_84
        GUESS   0364A114Eh,centipede
        GUESS   0F3A934CAh,choplifter_col
        GUESS   0BB1F0B92h,congo_bongo_col
        GUESS   036F05C16h,cosmic_avenger
        GUESS   069CD1483h,decathlon
        GUESS   098DFA5BFh,defender
        GUESS   0136625BAh,destructor
        GUESS   0F652A718h,donkey_kong
        GUESS   026596B83h,donkey_kong_alt
        GUESS   0A839110Ah,donkey_kong_jr
        GUESS   002204BC4h,dragonfire
        GUESS   001CFABF4h,dr_seuss
        GUESS   0514A22C1h,evolution
        GUESS   0F7A43291h,fathom
        GUESS   065112F20h,flipper_col
        GUESS   0E4E8D068h,fortune_builder
        GUESS   0733ABFBCh,fraction_fever
        GUESS   0C5492C5Bh,franctic_freddy
        GUESS   0862A48F6h,frenzy
        GUESS   05D29AD18h,frogger_col
        GUESS   07E559732h,frontline
        GUESS   0A4360827h,galaxi
        GUESS   00108119Fh,gateway_to_apshai
        GUESS   0D752B4F1h,gorf
        GUESS   0A994F48Fh,grogs_revenge
        GUESS   06BC08ABDh,grogs_revenge_alt
        GUESS   00A209BDDh,gust_buster
        GUESS   056FE9280h,gyruss
        GUESS   0C588CB02h,hero
        GUESS   0CD15D639h,illusions
        GUESS   0D15A3C87h,james_bond
        GUESS   058434600h,jukebox
        GUESS   0394B30E4h,jumpman_junior
        GUESS   0B024A8F4h,jungle_hunt
        GUESS   066328CB9h,keystone_kapers
        GUESS   00291BD7Fh,ken_uston_blackjack
        GUESS   0AD54C092h,lady_bug
        GUESS   08A1E6941h,learning_with_leeper
        GUESS   00F5DDEB2h,linking_logic
        GUESS   042985388h,looping
        GUESS   017857F16h,cosmo_fighter_2
        GUESS   0A3454F71h,miner_2049ER
        GUESS   0F72CE6E4h,montezuma_revenge
        GUESS   071FC03FEh,motocross_racer
        GUESS   03AA92FA1h,mountain_king
        GUESS   0540789BAh,moonsweeper
        GUESS   028DFFF3Eh,mousetrap
        GUESS   078904D24h,mr_do
        GUESS   008FEF526h,nova_blast
        GUESS   075E44CCFh,oils_well
        GUESS   08E8E0607h,omega_race
        GUESS   092841F06h,one_on_one
        GUESS   00973924Ch,pepper_ii
        GUESS   0DDC0E4F8h,pitfall
        GUESS   03DA26CC1h,pitfall_2
        GUESS   02CB4CFE6h,pit_stop
        GUESS   0FD31ADC7h,popeye
        GUESS   06A447BD9h,q_bert
        GUESS   0D7DBE98Fh,q_bert_2
        GUESS   012333AB8h,quest_for_quintana_roo
        GUESS   0019C1137h,river_raid
        GUESS   0B80B1E38h,robin_hood
        GUESS   007C74BB9h,roc_n_rope
        GUESS   02ADA5DB5h,rocky_super_action_boxing
        GUESS   07CF9FCEEh,rolloverture
        GUESS   02604A6EEh,sammy_lightfoot
        GUESS   04CCD277Ah,sector_alpha
        GUESS   0895230FDh,segas_carnival
        GUESS   0B5DDBC9Fh,sewer_sam
        GUESS   028362327h,sir_lancelot
        GUESS   080A284F7h,slither
        GUESS   05E4DD217h,slurpy
        GUESS   0BF9C3B0Fh,smurf_pnp_workshop
        GUESS   0C3E062DBh,smurf_rescue
        GUESS   053F3BD2Bh,space_fury
        GUESS   05E3E5967h,space_panic
        GUESS   0CFB85B27h,spectron
        GUESS   07F0D665Bh,spy_hunter
        GUESS   02D4E124Ah,squish_em_sam
        GUESS   012B2FB56h,star_trek
        GUESS   04B4D2C3Eh,star_wars_col
        GUESS   0CAEF91EEh,subroc
        GUESS   091DAD62Dh,sa_baseball
        GUESS   03AEBE2DCh,sa_football
        GUESS   0E56EFFBDh,super_cobra
        GUESS   053637D33h,super_controller_tester
        GUESS   0FEC01152h,super_cross_force
        GUESS   0B1CB262Fh,super_dk_junior
        GUESS   09AD363A6h,tapper
        GUESS   048EE1BF8h,tarzan
        GUESS   0CF282E36h,telly_turtle
        GUESS   04C727AB0h,time_pilot
        GUESS   0885C0B82h,dam_busters
        GUESS   055CF6185h,dukes_of_hazzard
        GUESS   0A8A1DF42h,the_heist
        GUESS   022C32385h,threshold
        GUESS   0DDC9E652h,tomarc_tb
        GUESS   0E86A12B0h,tournament_tennis
        GUESS   080BD0673h,turbo
        GUESS   08078288Ch,tutankamon
        GUESS   066AA54E2h,up_n_down
        GUESS   05F6DB2E7h,venture
        GUESS   0354CC99Dh,victory
        GUESS   0602DCD67h,war_games
        GUESS   049CBCEA8h,war_room
        GUESS   04E2B6FCEh,wing_war
        GUESS   00743B94Ch,zaxxon
        GUESS   0614DF7A0h,zenji
                
        dd      012345678h


code32          ends
                end

;Game: games\mickey_2.sms -> 07F1CD0D7h
;Game: games\beavisbu.gg -> 0BEE65BEFh
;Game: games\captamer.gg -> 0E33EB8F0h
;Game: games\ironman.gg -> 0329BFF2Bh
;Game: games\lastbib1.gg -> 082F6E339h
;Game: games\lastbib2.gg -> 01C6D45BDh
;Game: games\aleste.gg -> 06D6FBE4Ah
;Game: games\asterix.sms -> 092AFC665h
;Game: games\batmanro.gg -> 07BCD2D01h
;Game: games\bbnightm.sms -> 051BD1174h
;Game: games\monica2.sms -> 054453931h
;Game: games\starwars.sms -> 09ECB7688h
;Game: games\sfightr2.sms -> 0FA2772A5h
;Game: games\rygar.sms -> 0CC05857Ch
;Game: games\rygar-a.sms -> 03DC04410h
;Game: games\pengland.sms -> 003109DA6h
;Game: games\pgland-j.sms -> 004E60F2Ah
;Game: games\sdancer.sms -> 02CB75693h
;Game: games\pengland.sg -> 0B379B4ACh
;Game: games\gg1007.gg -> 09934B784h
;Game: games\rambo3.sms -> 08C2DA449h
