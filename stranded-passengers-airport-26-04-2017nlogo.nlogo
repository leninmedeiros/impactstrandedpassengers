; IMPACT - Stranded Passengers Model
; CODE By Lenin Medeiros & Natalie van der Wal
; Vrije Universiteit Amsterdam
; April, 2017
__includes [ "IMPACT-environment-airport.nls" "model.nls"]
breed [passengers passenger]
breed [staff_members staff_member]
breed [gates gate]
breed [restaurants restaurant]
breed [seats seat]
breed [toilets toilet]

globals [
  chairs_positions
  n_o_s
  gates_positions
  restaurants_positions
  pillars_positions
  information_desks_positions
  seats_positions_1
  psa
  current_time
  current_time_hours
  current_time_minutes
  current_time_seconds
  is-gate-open?
  previous_boarding_time
  avg_frustration
  avg_frustration_male
  avg_frustration_female
  ;initial_boarding_time
  enjoying
  enjoying_men
  enjoying_women
  enjoying_young
  enjoying_adolescent
  enjoying_adult
  enjoying_elder
  enjoying_commuters
  enjoying_holidaymakers
  enjoying_parents
  enjoying_nonparents
  enjoying_in_a_hurry
  enjoying_not_in_a_hurry
  enjoying_in_a_group
  enjoying_alone
  seeking_for_information
  seeking_for_information_men
  seeking_for_information_women
  seeking_for_information_young
  seeking_for_information_adolescent
  seeking_for_information_adult
  seeking_for_information_elder
  seeking_for_information_commuters
  seeking_for_information_holidaymakers
  seeking_for_information_parents
  seeking_for_information_nonparents
  seeking_for_information_in_a_hurry
  seeking_for_information_not_in_a_hurry
  seeking_for_information_in_a_group
  seeking_for_information_alone
  aggressive
  aggressive_men
  aggressive_women
  aggressive_young
  aggressive_adolescent
  aggressive_adult
  aggressive_elder
  aggressive_commuters
  aggressive_holidaymakers
  aggressive_parents
  aggressive_nonparents
  aggressive_in_a_hurry
  aggressive_not_in_a_hurry
  aggressive_in_a_group
  aggressive_alone
  secundary_actions
  fem_threshold
  men_threshold
  answer
  yelling
  intimidating
  using_force
  seating
  in_the_toilet
  in_a_restaurant
  walking_around
  asking
  nat_clusters_distribution
  percentage_misbehaving_men
  percentage_misbehaving_women
  misbehaviours
  misbehaviours_men
  misbehaviours_women
  total_yelling
  total_yelling_men
  total_yelling_women
  total_intimidating
  total_intimidating_men
  total_intimidating_women
  total_using_force
  total_using_force_men
  total_using_force_women
  total_misbehaviours_young
  total_yelling_young
  total_using_force_young
  total_intimidating_young
  total_misbehaviours_adolescent
  total_yelling_adolescent
  total_using_force_adolescent
  total_intimidating_adolescent
  total_misbehaviours_adult
  total_yelling_adult
  total_using_force_adult
  total_intimidating_adult
  total_misbehaviours_elder
  total_yelling_elder
  total_using_force_elder
  total_intimidating_elder
  total_misbehaviours_commuters
  total_yelling_commuters
  total_using_force_commuters
  total_intimidating_commuters
  total_misbehaviours_holidaymakers
  total_yelling_holidaymakers
  total_using_force_holidaymakers
  total_intimidating_holidaymakers
  total_misbehaviours_parents
  total_yelling_parents
  total_using_force_parents
  total_intimidating_parents
  total_misbehaviours_nonparents
  total_yelling_nonparents
  total_using_force_nonparents
  total_intimidating_nonparents
  total_misbehaviours_travelling_alone
  total_yelling_travelling_alone
  total_using_force_travelling_alone
  total_intimidating_travelling_alone
  total_misbehaviours_travelling_in_groups
  total_yelling_travelling_in_groups
  total_using_force_travelling_in_groups
  total_intimidating_travelling_in_groups
  total_misbehaviours_in_a_hurry
  total_yelling_in_a_hurry
  total_using_force_in_a_hurry
  total_intimidating_in_a_hurry
  total_misbehaviours_not_in_a_hurry
  total_yelling_not_in_a_hurry
  total_using_force_not_in_a_hurry
  total_intimidating_not_in_a_hurry
]

passengers-own [
  age_group
  gender
  commuter?
  in_a_hurry?
  parent?
  nationality_cluster
  frustration_level
  old_frustration_level
  goal
  hope
  intention
  internal_threshold
  action
  seated?
  pseat
  original_size
  is-asking-question?
  group
  number_of_misbehaviours
  times_yelling
  times_intimidating
  times_using_force
]

gates-own [
  is-open?
]

seats-own [
  is-occupied?
  seated_passenger
]

restaurants-own [
  is-open?
]

toilets-own [
  is-open?
]

to init-global-variables
  set is-gate-open? false
  set boarding_time boarding_time
  set current_time "00:00:00"
  set current_time_hours 0
  set current_time_minutes 0
  set current_time_seconds 0
  set enjoying 0
  set seeking_for_information 0
  set aggressive 0
  set secundary_actions ["to sit" "to go to the toilet" "to walk" "to go to a restaurant"]
  set men_threshold .6
  set fem_threshold .7
  set answer 2
  set yelling 0
  set intimidating 0
  set using_force 0
  set seating 0
  set in_the_toilet 0
  set in_a_restaurant 0
  set walking_around 0
  set asking 0
end

to setup
  setup-environment
  init-global-variables
  update-psa
  update-passengers
end

to go
  if current_time = "01:00:00" or current_time = "02:00:00" [
    calculate-total-numbers
  ]
  ifelse not open_toilets?
  [
    ask toilets [
      set label "OUT OF ORDER"
    ]
  ]
  [
    ask toilets [
      set label ""
    ]
  ]
  ifelse not open_restaurants?
  [
    ask restaurants [
      set label "CLOSED"
    ]
  ]
  [
    ask restaurants [
      set label "OPEN"
    ]
  ]
  ifelse current_time = "02:00:00" or psa = "Now boarding."
  [
    stop
  ]
  [
    validate-boarding-time
    reset-staff
    update-gate
    update-passengers
    tick
    set_current_time
  ]
end

to update-passengers
  ask passengers [
    set old_frustration_level frustration_level
  ]
  update-belief
  update-frustration
  if chat_bot [
    chat-bot
  ]
  update-intention
  if ticks = 0 or ticks mod 120 = 0 [
    update-action
  ]
  if emotion_contagion? [
    update-frustration-emotion-contagion
  ]
  update-frustration-shape
  update-stats
end

to update-frustration-shape
  ask passengers [
    ifelse not commuter?
    [
      ifelse (gender = "M" and frustration_level > men_threshold) or (gender = "F" and frustration_level > fem_threshold)
      [
        set shape "person frustrated"
      ]
      [
        set shape "person"
      ]
    ]
    [
      ifelse (gender = "M" and frustration_level > men_threshold) or (gender = "F" and frustration_level > fem_threshold)
      [
        set shape "person business frustrated"
      ]
      [
        set shape "person business"
      ]
    ]
  ]
end

to update-stats
  set avg_frustration mean [frustration_level] of passengers
  ifelse count passengers with [gender = "M"] > 0
  [
    set avg_frustration_male mean [frustration_level] of passengers with [gender = "M"]
  ]
  [
    set avg_frustration_male 0
  ]
  ifelse count passengers with [gender = "F"] > 0
  [
    set avg_frustration_female mean [frustration_level] of passengers with [gender = "F"]
  ]
  [
    set avg_frustration_female 0
  ]
  set enjoying count passengers with [intention = "to enjoy the trip"]

  set seeking_for_information count passengers with [intention = "to seek for information"]
  set aggressive count passengers with [intention = "to become aggressive"]
  set yelling count passengers with [action = "to yell"]
  set intimidating count passengers with [action = "to intimidate"]
  set using_force count passengers with [action = "to use force"]
end

to update-gate
  if boarding_time = current_time [
    open-gate 2
  ]
end

to validate-boarding-time
  let valid? true
  if (length boarding_time != 8) or item 2 boarding_time != ":" or item 5 boarding_time != ":" [
    set valid? false
  ]
  carefully
  [
    let h1 read-from-string item 0 boarding_time
    let h2 read-from-string item 1 boarding_time
    let m1 read-from-string item 3 boarding_time
    let m2 read-from-string item 4 boarding_time
    let s1 read-from-string item 6 boarding_time
    let s2 read-from-string item 7 boarding_time
    if (not (h1 >= 0 and h1 <= 2)) or (not (h2 >= 0 and h2 <= 9)) or (not (m1 >= 0 and m1 <= 6)) or (not (m2 >= 0 and m2 <= 9)) or (not (s1 >= 0 and s1 <= 6)) or (not (s2 >= 0 and s2 <= 9))
    [
      set valid? false
    ]
  ]
  [
    set valid? false
  ]

  if valid? [
    let h read-from-string substring boarding_time 0 2
    let m read-from-string substring boarding_time 3 5
    let s read-from-string substring boarding_time 6 8
    let btit ((h * 60 * 60) + (m * 60) + s)
    if btit < ticks and not is-gate-open? [
      set valid? false
    ]
  ]


  if not valid?
  [
    set boarding_time "Unknown."
  ]
  update-psa
end

to update-psa
  ifelse is-gate-open?
  [
    set psa "Now boarding."
  ]
  [
    ifelse boarding_time = "Unknown."
    [
      set psa "Flight delayed. More information soon."
    ]
    [
      set psa (word "Expected boarding time: " boarding_time ".")
    ]
  ]
end

to set_current_time
  set current_time_seconds (current_time_seconds + 1)
  if current_time_seconds = 60 [
    set current_time_seconds 0
    set current_time_minutes (current_time_minutes + 1)
    if current_time_minutes = 60 [
      set current_time_minutes 0
      set current_time_hours (current_time_hours + 1)
    ]
  ]
  let ts (word current_time_seconds)
  let tm (word current_time_minutes)
  let th (word current_time_hours)
  if current_time_seconds < 10
  [
    set ts (word "0" current_time_seconds)
  ]
  if current_time_minutes < 10
  [
    set tm (word "0" current_time_minutes)
  ]
  if current_time_hours < 10
  [
    set th (word "0" current_time_hours)
  ]
  set current_time (word th ":" tm ":" ts)
end

to open-gate [gate_id]
  if not is-gate-open? [
    ask gate gate_id [
      set is-open? true
      set is-gate-open? is-open?
      ask patch-here [
        set pcolor green
        ask neighbors [
          if pcolor != grey [
            set pcolor green
          ]
        ]
      ]
    ]
    set boarding_time current_time
    update-psa
  ]
end

to-report compare-time [t1 t2]
  let h1 read-from-string substring t1 0 2
  let m1 read-from-string substring t1 3 5
  let s1 read-from-string substring t1 6 8
  let h2 read-from-string substring t2 0 2
  let m2 read-from-string substring t2 3 5
  let s2 read-from-string substring t2 6 8
  let is-t1-greater? false
  if (h1 > h2) or (h1 = h2 and m1 > m2) or (h1 = h2 and m1 = m2 and s1 > s2) [
    set is-t1-greater? true
  ]
  report is-t1-greater?
end

to-report difference-boarding-times [t1 t2]
  let h1 read-from-string substring t1 0 2
  let m1 read-from-string substring t1 3 5
  let s1 read-from-string substring t1 6 8
  let h2 read-from-string substring t2 0 2
  let m2 read-from-string substring t2 3 5
  let s2 read-from-string substring t2 6 8
  let t1ticks (s1 + (m1 * 60) + (h1 * 60 * 60))
  let t2ticks (s2 + (m2 * 60) + (h2 * 60 * 60))
  report (t1ticks - t2ticks)
end

to update-belief
  ask passengers [
    ifelse is-gate-open? or boarding_time = initial_boarding_time
    [
      set hope true
    ]
    [
      if boarding_time = "Unknown." or compare-time boarding_time initial_boarding_time [
        set hope false
      ]
    ]
  ]
end

to update-action
  ask seats with [who >= 24 and who <= 423] [
    set seated_passenger nobody
    set color 84
    set is-occupied? false
  ]
  ask passengers [
    if hidden? [
      show-turtle
    ]
    set seated? false
    set pseat nobody
    set size original_size
    ifelse intention = "to enjoy the trip"
    [
      if is-asking-question? [
        set is-asking-question? false
      ]
      set action item random 4 secundary_actions
      ifelse action = "to sit"
      [
        let c color
        let x 0
        let y 0
        let ps 0
        let sp who
        ask one-of seats with [not is-occupied? and who >= 24 and who <= 423] [
          set color c
          set x xcor
          set y ycor
          set ps who
          set is-occupied? true
          set seated_passenger sp
        ]
        setxy x y
        set seated? true
        set pseat ps
        set size 0.001
      ]
      [
        if action = "to go to the toilet" and open_toilets? [
          setxy 77 48
        ]
        if action = "to walk" [
          walk-around who
        ]
        if action = "to go to a restaurant" and open_restaurants? [
          let i random 2
          let r item i restaurants_positions
          setxy item 0 r item 1 r
        ]
      ]
      if (action = "to go to a restaurant" and not open_restaurants?) or (action = "to go to the toilet" and not open_toilets?) [
        set frustration_level (frustration_level + 0.00005)
        set action "to walk"
        walk-around who
      ]
    ]
    [
      let chance_go_to_a_staff_member random 100
      ifelse not is-asking-question? and chance_go_to_a_staff_member > 50[
        get-a-spot-around-a-service-desk-or-a-staff-member who
      ]
      [
        walk-around who
        set is-asking-question? false
      ]
    ]
  ]
  if ticks mod 1800 = 0 [
    action_selection
  ]
end

to walk-around [pid]
  ask passenger pid [
    let x 0
    let y 0
    ask one-of patches with [pcolor = black and count turtles-here = 0] [
      set x pxcor
      set y pycor
    ]
    setxy x y
  ]
end

to get-a-spot-around-a-service-desk-or-a-staff-member [pid]
  ask passenger pid [
    let xtemp xcor
    let ytemp ycor
    let nsm item 0 sort-on [distance myself] staff_members
    let dnsm distance nsm
    let did distance (turtle 15)
    let iidmc? false
    if did <= dnsm [
      set iidmc? true
    ]
    ifelse iidmc?
    [
      ask turtle 15 [ask item 0 sort-on [distance myself] patches in-cone 15 360 with [count turtles-here = 0 and pcolor = black] [set xtemp pxcor set ytemp pycor]]
    ]
    [
      ask nsm [ask item 0 sort-on [distance myself] patches in-cone 9 360 with [count turtles-here = 0] [set xtemp pxcor set ytemp pycor]]
    ]
    setxy xtemp ytemp
    set is-asking-question? true
  ]
end

to calculate-total-numbers2
  set misbehaviours 0
  set total_yelling 0
  set total_intimidating 0
  set total_using_force 0
  ask passengers [
    set misbehaviours (misbehaviours + number_of_misbehaviours)
    set total_yelling (total_yelling + times_yelling)
    set total_intimidating (total_intimidating + times_intimidating)
    set total_using_force (total_using_force + times_using_force)
  ]
end

to calculate-total-numbers
  set misbehaviours 0
  set misbehaviours_men 0
  set misbehaviours_women 0
  set total_yelling 0
  set total_yelling_men 0
  set total_yelling_women 0
  set total_intimidating 0
  set total_intimidating_men 0
  set total_intimidating_women 0
  set total_using_force 0
  set total_using_force_men 0
  set total_using_force_women 0
  ask passengers [
    set misbehaviours (misbehaviours + number_of_misbehaviours)
    set total_yelling (total_yelling + times_yelling)
    set total_intimidating (total_intimidating + times_intimidating)
    set total_using_force (total_using_force + times_using_force)
    ifelse gender = "M"
    [
      set misbehaviours_men (misbehaviours_men + number_of_misbehaviours)
      set total_yelling_men (total_yelling_men + times_yelling)
      set total_intimidating_men (total_intimidating_men + times_intimidating)
      set total_using_force_men (total_using_force_men + times_using_force)
    ]
    [
      set misbehaviours_women (misbehaviours_women + number_of_misbehaviours)
      set total_yelling_women (total_yelling_women + times_yelling)
      set total_intimidating_women (total_intimidating_women + times_intimidating)
      set total_using_force_women (total_using_force_women + times_using_force)
    ]

    if age_group = "young" [
      set total_misbehaviours_young (total_misbehaviours_young + number_of_misbehaviours)
      set total_yelling_young (total_yelling_young + times_yelling)
      set total_using_force_young (total_using_force_young + times_using_force)
      set total_intimidating_young (total_intimidating_young + times_intimidating)
    ]

    if age_group = "adolescent" [
      set total_misbehaviours_adolescent (total_misbehaviours_adolescent + number_of_misbehaviours)
      set total_yelling_adolescent (total_yelling_adolescent + times_yelling)
      set total_using_force_adolescent (total_using_force_adolescent + times_using_force)
      set total_intimidating_adolescent (total_intimidating_adolescent + times_intimidating)
    ]

    if age_group = "adult" [
      set total_misbehaviours_adult (total_misbehaviours_adult + number_of_misbehaviours)
      set total_yelling_adult (total_yelling_adult + times_yelling)
      set total_using_force_adult (total_using_force_adult + times_using_force)
      set total_intimidating_adult (total_intimidating_adult + times_intimidating)
    ]

    if age_group = "elder" [
      set total_misbehaviours_elder (total_misbehaviours_elder + number_of_misbehaviours)
      set total_yelling_elder (total_yelling_elder + times_yelling)
      set total_using_force_elder (total_using_force_elder + times_using_force)
      set total_intimidating_elder (total_intimidating_elder + times_intimidating)
    ]

    ifelse commuter?
    [
      set total_misbehaviours_commuters (total_misbehaviours_commuters + number_of_misbehaviours)
      set total_yelling_commuters (total_yelling_commuters + times_yelling)
      set total_using_force_commuters (total_using_force_commuters + times_using_force)
      set total_intimidating_commuters (total_intimidating_commuters + times_intimidating)
    ]
    [
      set total_misbehaviours_holidaymakers (total_misbehaviours_holidaymakers + number_of_misbehaviours)
      set total_yelling_holidaymakers (total_yelling_holidaymakers + times_yelling)
      set total_using_force_holidaymakers (total_using_force_holidaymakers + times_using_force)
      set total_intimidating_holidaymakers (total_intimidating_holidaymakers + times_intimidating)
    ]

    ifelse in_a_hurry?
    [
      set total_misbehaviours_in_a_hurry (total_misbehaviours_in_a_hurry + number_of_misbehaviours)
      set total_yelling_in_a_hurry (total_yelling_in_a_hurry + times_yelling)
      set total_using_force_in_a_hurry (total_using_force_in_a_hurry + times_using_force)
      set total_intimidating_in_a_hurry (total_intimidating_in_a_hurry + times_intimidating)
    ]
    [
      set total_misbehaviours_not_in_a_hurry (total_misbehaviours_not_in_a_hurry + number_of_misbehaviours)
      set total_yelling_not_in_a_hurry (total_yelling_not_in_a_hurry + times_yelling)
      set total_using_force_not_in_a_hurry (total_using_force_not_in_a_hurry + times_using_force)
      set total_intimidating_not_in_a_hurry (total_intimidating_not_in_a_hurry + total_intimidating)
    ]

    ifelse parent?
    [
      set total_misbehaviours_parents (total_misbehaviours_parents + number_of_misbehaviours)
      set total_yelling_parents (total_yelling_parents + times_yelling)
      set total_using_force_parents (total_using_force_parents + times_using_force)
      set total_intimidating_parents (total_intimidating_parents + times_intimidating)
    ]
    [
      set total_misbehaviours_nonparents (total_misbehaviours_nonparents + number_of_misbehaviours)
      set total_yelling_nonparents (total_yelling_nonparents + times_yelling)
      set total_using_force_nonparents (total_using_force_nonparents + times_using_force)
      set total_intimidating_nonparents (total_intimidating_nonparents + times_intimidating)
    ]

    ifelse group != "?"
    [
      set total_misbehaviours_travelling_in_groups (total_misbehaviours_travelling_in_groups + number_of_misbehaviours)
      set total_yelling_travelling_in_groups (total_yelling_travelling_in_groups + times_yelling)
      set total_using_force_travelling_in_groups (total_using_force_travelling_in_groups + times_using_force)
      set total_intimidating_travelling_in_groups (total_intimidating_travelling_in_groups + times_intimidating)
    ]
    [
      set total_misbehaviours_travelling_alone (total_misbehaviours_travelling_alone + number_of_misbehaviours)
      set total_yelling_travelling_alone (total_yelling_travelling_alone + times_yelling)
      set total_using_force_travelling_alone (total_using_force_travelling_alone + times_using_force)
      set total_intimidating_travelling_alone (total_intimidating_travelling_alone + times_intimidating)
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
3
10
1794
782
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
136
0
56
0
0
1
ticks
30.0

BUTTON
3
781
68
855
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
3
854
190
887
number_of_staff
number_of_staff
1
9
9
1
1
people
HORIZONTAL

SLIDER
595
781
796
814
percentage_of_female
percentage_of_female
0
100
50
1
1
%
HORIZONTAL

SLIDER
796
781
1027
814
percentage_of_commuters
percentage_of_commuters
0
100
50
1
1
%
HORIZONTAL

BUTTON
67
781
129
855
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
127
781
190
855
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1027
781
1227
814
number_of_passengers
number_of_passengers
80
250
250
1
1
NIL
HORIZONTAL

MONITOR
595
814
1026
887
Announcement
psa
17
1
18

MONITOR
1026
814
1227
887
Current Time
current_time
17
1
18

BUTTON
190
781
595
814
To open the gate number 2.
open-gate 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
330
756
480
775
Gate 2
15
0.0
1

INPUTBOX
190
813
595
887
boarding_time
Unknown.
1
0
String

PLOT
3
887
596
1396
Average Frustration Level
Time
Frustration Level
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Total" 1.0 0 -7500403 true "" "plot avg_frustration"
"Male" 1.0 0 -2674135 true "" "plot avg_frustration_male"
"Female" 1.0 0 -955883 true "" "plot avg_frustration_female"

PLOT
595
887
1227
1396
Intentions
Time
Number of Passengers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"To enjoy the trip" 1.0 0 -16777216 true "" "plot enjoying"
"To seek for information" 1.0 0 -7500403 true "" "plot seeking_for_information"
"To become aggressive" 1.0 0 -2674135 true "" "plot aggressive"

SWITCH
1794
749
1964
782
open_restaurants?
open_restaurants?
0
1
-1000

PLOT
1227
814
1976
1399
Actions
Time
Number of Passengers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Seating" 1.0 0 -16777216 true "" "plot seating"
"Walking" 1.0 0 -7500403 true "" "plot walking_around"
"In the toilet" 1.0 0 -2674135 true "" "plot in_the_toilet"
"In a restaurant" 1.0 0 -955883 true "" "plot in_a_restaurant"
"Just asking questions" 1.0 0 -6459832 true "" "plot asking"
"Yelling" 1.0 0 -1184463 true "" "plot yelling"
"Intimidating" 1.0 0 -10899396 true "" "plot intimidating"
"Using force" 1.0 0 -13840069 true "" "plot using_force"

SWITCH
1794
619
1904
652
chat_bot
chat_bot
1
1
-1000

SWITCH
1794
782
1973
815
multi_language_staff
multi_language_staff
1
1
-1000

SLIDER
1227
781
1418
814
_groups_of_3_ratio
_groups_of_3_ratio
0
100
10
1
1
%
HORIZONTAL

SLIDER
1609
781
1794
814
_groups_of_2_ratio
_groups_of_2_ratio
0
100
10
1
1
%
HORIZONTAL

SLIDER
1418
781
1610
814
_groups_of_4_ratio
_groups_of_4_ratio
0
100
80
1
1
%
HORIZONTAL

SWITCH
1794
585
1966
618
emotion_contagion?
emotion_contagion?
1
1
-1000

SWITCH
1794
717
1931
750
open_toilets?
open_toilets?
0
1
-1000

SLIDER
1794
684
2056
717
_percentage_people_travelling_alone
_percentage_people_travelling_alone
0
100
0
1
1
%
HORIZONTAL

SLIDER
1794
650
2004
683
passengers_in_a_hurry
passengers_in_a_hurry
0
100
50
1
1
%
HORIZONTAL

SLIDER
1794
34
2061
67
arab_distribution
arab_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
67
2061
100
near_east_distribution
near_east_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
99
2061
132
latin_america_distribution
latin_america_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
132
2061
165
east_europe_distribution
east_europe_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
164
2061
197
latin_europe_distribution
latin_europe_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
197
2061
230
nordic_distribution
nordic_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
229
2061
262
germanic_distribution
germanic_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
259
2061
292
african_distribution
african_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
292
2061
325
anglo_distribution
anglo_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
324
2061
357
confucian_distribution
confucian_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

SLIDER
1794
354
2061
387
far_east_distribution
far_east_distribution
0
100
9.09
0.01
1
%
HORIZONTAL

INPUTBOX
1794
387
2061
481
initial_boarding_time
04:00:00
1
0
String

SWITCH
1794
482
1897
515
kids
kids
0
1
-1000

SWITCH
1794
519
2041
552
everybody_from_latin_europe?
everybody_from_latin_europe?
1
1
-1000

SWITCH
1794
554
2041
587
groups_evenly_divided?
groups_evenly_divided?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a model of stranded passengers in a departure lounge at Fiumicino airport.

## HOW IT WORKS

As soon as there is a delay in the flight the passengers are waiting for, they start to get frustrated. If the frustration level of a given passenger reaches the pre-defined threshold (0.8) he or she will start to misbehave. The types of their misbehaviours depend on both gender and age.

## HOW TO USE IT

Select the parameters in the interface before clicking on Setup. Note that the boarding time should following this format: HH:MM:SS. You can also put "Unknown." as boarding time. After dealing with the initial parameters, click on Go.

## THINGS TO NOTICE

Note that the simulation is a way slower with the effect of emotional contagion than without it. This happens because, in order to calculate the influence the passengers can exert on each other's frustration levels, the model performs some background computation in a considerable loop.

## THINGS TO TRY

Try to play a bit with all the parameters and keep checking the plots for overall frustration level by gender, intentions and actions (bellow the configuration buttons).

## EXTENDING THE MODEL

We intend to extend the model in the future by, among other things:
- Translating it to Python since it has more computational power than NetLogo and facilitates things like putting the model to run on the cloud;
- Dealing wth more than one flight at same time.

## NETLOGO FEATURES

Take a look on NetLogo's BehaviorSpace to see how to perform experiments with this model. You can easily find more details about this tool here: https://ccl.northwestern.edu/netlogo/docs/behaviorspace.html.

## RELATED MODELS

We took the model by van der Wal, Couwenberg & Bosse as inspiration. Such a model represents stranded passengers in a train. The reference is below.

Wal, C.N. van der, Couwenberg, M., and Bosse, T., Getting Frustrated: Modelling Emotion Contagion in Stranded Passengers. In: Proceedings of the 30th International Conference on Industrial, Engineering & Other Applications of Applied Intelligent Systems, IEA/AIE'17. Springer Verlag, Lecture Notes in Artificial Intelligence, 2017, to appear.

## CREDITS AND REFERENCES

Lenin Medeiros & Natalie van der Wal
{l.medeiros,c.n.vander.wal}@vu.nl
IMPACT - European Comission
Vrije Universiteit Amsterdam
University of Leeds

The authors would like to state that Lenin Medeiros' stay at Vrije Universtiteit Amsterdam was funded by the Brazilian Science without Borders (SwB) program. This work was realized with the support from CNPq, National Council for Scientific and Technological Development - Brazil, through a scholarship which reference number is 235134/2014-7.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird 2
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

entrance
false
0
Rectangle -7500403 true true 45 45 75 105
Rectangle -7500403 true true 45 195 75 255
Rectangle -7500403 true true 45 45 255 75
Rectangle -7500403 true true 45 225 255 255
Rectangle -7500403 true true 225 45 255 255
Rectangle -7500403 true true 15 135 165 165
Polygon -7500403 true true 150 105 210 150 150 195

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flight-departure-gate
false
0
Polygon -7500403 true true 298 6 298 39 30 298 3 298 1 271 113 160 21 75 24 22 200 67 269 0
Polygon -7500403 true true 45 240 0 240 0 300 45 240

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

information
false
10
Circle -13345367 true true 23 23 255
Polygon -1 true false 120 225 180 225 165 120 135 120
Circle -1 true false 129 69 42

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person business frustrated
false
0
Rectangle -1 true false 120 90 180 180
Polygon -2674135 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -2674135 true false 110 5 80
Rectangle -2674135 true false 127 76 172 91
Line -2674135 false 172 90 161 94
Line -2674135 false 128 90 139 94
Polygon -2674135 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -10899396 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person frustrated
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -2674135 true false 110 5 80

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

restaurant
false
0
Rectangle -7500403 true true 30 75 45 135
Rectangle -7500403 true true 60 75 75 135
Rectangle -7500403 true true 90 75 105 135
Rectangle -7500403 true true 30 135 105 150
Rectangle -7500403 true true 60 150 75 225
Rectangle -7500403 true true 150 75 165 225
Rectangle -7500403 true true 135 75 150 150
Rectangle -7500403 true true 225 150 240 210
Rectangle -7500403 true true 195 210 270 225
Polygon -7500403 true true 210 150 195 120 195 75 270 75 270 120 255 150

seat
false
0
Rectangle -7500403 true true 120 120 180 180

seat-block-4
false
0
Rectangle -13345367 true false 75 90 135 150
Rectangle -13345367 true false 165 90 225 150
Rectangle -13345367 true false 75 180 135 240
Rectangle -13345367 true false 165 180 225 240

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

toilet
false
0
Polygon -7500403 true true 45 75 75 75 90 105 105 75 135 75 135 150 120 165 105 255 75 255 60 165 45 150 45 75
Circle -7500403 true true 69 24 42
Line -7500403 true 150 30 150 240
Circle -7500403 true true 189 24 42
Polygon -7500403 true true 165 75 195 75 210 105 225 75 240 75 255 180 225 180 225 255 195 255 195 180 165 180 180 75

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

warning
false
0
Polygon -7500403 true true 0 240 15 270 285 270 300 240 165 15 135 15
Polygon -16777216 true false 180 75 120 75 135 180 165 180
Circle -16777216 true false 129 204 42

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>avg_frustration</metric>
    <metric>avg_frustration_male</metric>
    <metric>avg_frustration_female</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open_toilets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confucian_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_staff">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open_restaurants?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arab_distribution">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_groups_of_4_ratio">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage_of_female">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="multi_language_staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="anglo_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emotion_contagion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="east_europe_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="far_east_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="near_east_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="passengers_in_a_hurry">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_groups_of_2_ratio">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage_of_commuters">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chat_bot">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nordic_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="germanic_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_groups_of_3_ratio">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="latin_europe_distribution">
      <value value="11.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_percentage_people_travelling_alone">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="latin_america_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="african_distribution">
      <value value="9.09"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="effect_of_gender_test" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>avg_frustration</metric>
    <metric>avg_frustration_male</metric>
    <metric>avg_frustration_female</metric>
    <metric>misbehaviours</metric>
    <metric>misbehaviours_men</metric>
    <metric>misbehaviours_women</metric>
    <metric>total_yelling</metric>
    <metric>total_yelling_men</metric>
    <metric>total_yelling_women</metric>
    <metric>total_intimidating</metric>
    <metric>total_intimidating_men</metric>
    <metric>total_intimidating_women</metric>
    <metric>total_using_force</metric>
    <metric>total_using_force_men</metric>
    <metric>total_using_force_women</metric>
    <metric>enjoying</metric>
    <metric>enjoying_men</metric>
    <metric>enjoying_women</metric>
    <metric>seeking_for_information</metric>
    <metric>seeking_for_information_men</metric>
    <metric>seeking_for_information_women</metric>
    <metric>aggressive</metric>
    <metric>aggressive_men</metric>
    <metric>aggressive_women</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
      <value value="&quot;02:00:00&quot;"/>
      <value value="&quot;20:00:00&quot;"/>
      <value value="&quot;04:00:00&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage_of_female">
      <value value="0"/>
      <value value="100"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="80"/>
      <value value="250"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="social-contagion-effect" repetitions="8" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>avg_frustration</metric>
    <metric>misbehaviours</metric>
    <metric>total_yelling</metric>
    <metric>total_intimidating</metric>
    <metric>total_using_force</metric>
    <metric>enjoying</metric>
    <metric>seeking_for_information</metric>
    <metric>aggressive</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
      <value value="&quot;02:00:00&quot;"/>
      <value value="&quot;20:00:00&quot;"/>
      <value value="&quot;04:00:00&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="80"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emotion_contagion?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="traveller-type-and-rush-effect" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>misbehaviours</metric>
    <metric>total_yelling</metric>
    <metric>total_intimidating</metric>
    <metric>total_using_force</metric>
    <metric>total_misbehaviours_commuters</metric>
    <metric>total_yelling_commuters</metric>
    <metric>total_using_force_commuters</metric>
    <metric>total_intimidating_commuters</metric>
    <metric>total_misbehaviours_holidaymakers</metric>
    <metric>total_yelling_holidaymakers</metric>
    <metric>total_using_force_holidaymakers</metric>
    <metric>total_intimidating_holidaymakers</metric>
    <metric>total_misbehaviours_parents</metric>
    <metric>total_yelling_parents</metric>
    <metric>total_using_force_parents</metric>
    <metric>total_intimidating_parents</metric>
    <metric>total_misbehaviours_nonparents</metric>
    <metric>total_yelling_nonparents</metric>
    <metric>total_using_force_nonparents</metric>
    <metric>total_intimidating_nonparents</metric>
    <metric>total_misbehaviours_in_a_hurry</metric>
    <metric>total_yelling_in_a_hurry</metric>
    <metric>total_using_force_in_a_hurry</metric>
    <metric>total_intimidating_in_a_hurry</metric>
    <metric>total_misbehaviours_not_in_a_hurry</metric>
    <metric>total_yelling_not_in_a_hurry</metric>
    <metric>total_using_force_not_in_a_hurry</metric>
    <metric>total_intimidating_not_in_a_hurry</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
      <value value="&quot;02:00:00&quot;"/>
      <value value="&quot;20:00:00&quot;"/>
      <value value="&quot;04:00:00&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="passengers_in_a_hurry">
      <value value="0"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="80"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage_of_commuters">
      <value value="0"/>
      <value value="100"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="kids">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="effect-of-services" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>misbehaviours</metric>
    <metric>total_yelling</metric>
    <metric>total_intimidating</metric>
    <metric>total_using_force</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
      <value value="&quot;02:00:00&quot;"/>
      <value value="&quot;20:00:00&quot;"/>
      <value value="&quot;04:00:00&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open_toilets?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="80"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open_restaurants?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="effect-of-crowd-composition" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>misbehaviours</metric>
    <metric>total_yelling</metric>
    <metric>total_intimidating</metric>
    <metric>total_using_force</metric>
    <enumeratedValueSet variable="boarding_time">
      <value value="&quot;Unknown.&quot;"/>
      <value value="&quot;02:00:00&quot;"/>
      <value value="&quot;20:00:00&quot;"/>
      <value value="&quot;04:00:00&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_of_passengers">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="everybody_from_latin_europe?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="groups_evenly_divided?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emotion_contagion?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
