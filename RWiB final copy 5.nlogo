globals [
  min-value-E ;minimum errors, for stars ungraded bipolar only, see setup and "Stars - Number of Erros" plot code for more
  min-value-P
  x-counter
  receptive-field
  number-of-stars
]

turtles-own
[
  ;universal variables
  center-rods ; turtles on the same patch - represents center receptive field
  surround-rods ; turtles on neighboring patches - represents surround receptive field
  vesicle-sum ; sum of all vesicles released in last three (length of lists) ticks
  synapse-strength ; difference between the absolute value number of vesicles released in past three (length of lists) ticks, represents activation of bipolar neuron after lateral inhibition
  surround-center-ratio ; factor that normalizes the center activation / inhibition to the surround activation / inhibition
  center-radius
  surround-radius
  index-position ; to iterate through lists

  ;poisson model variables
  unitary-vesicle-history ; list containing number of unitary vesicle events in the last three (length of list) ticks
  poisson-multiplier ; hard coded as 1 (when vesicle release is not suppressed by photon) and 0.25 (when vesicle release is supressed by photons)

  ;erlang model variables
  multivesicle-history ; list containing number of multivesicle events in the last three (length of list) ticks
  erlang-counter ; counts poisson events that add up to erlang factor which causes multivesicle release
  erlang-poisson-spontaneous-release-rate ; the mean for the poisson events that lead to multivesicular release
  erlang-factor ;the sum the poisson events must reach to trigger multivesicular event
  multivesicular-number ;the number of vesicles released per multivesicular event, currently set as half basal vesicle release to keep number of vesicles released equal always

]

to setup
  ca
  set x-counter 0 ; used for plotting to reset x value after reseting plots during a run
  ifelse image = "stars"
  [
    set number-of-stars 40
    ask patches [set pcolor black]
    ask n-of number-of-stars patches [set pcolor white]
  ]
  [import-pcolors file-path]

  ask patches
  [
    set receptive-field 5
    sprout receptive-field
  ]

  ask turtles
  [
    set color black
    set size 1.4
    set shape "square"
    set unitary-vesicle-history [0 0 0] ;each tick and index of list is 1/3 second, allows for ~ 1/3 second inhibition (Campbell and Westheimer, 1960), and 1 second "memory" of bipolar cells (Denny and Gaines, 2000)
    set multivesicle-history [0 0 0]
    set erlang-factor 620 ; 100 *  erlang factor (Hays et al., 2021), allows for more place values in random poisson
    set multivesicular-number basal-vesicle-release-per-second / 2 ; coded to be two per second, (Hays et al., 2021)
    set erlang-counter random (erlang-factor + 1) ; turtles in erlang model start at random point in count up to erlang factor
    set center-radius 0
    set surround-radius 1
    set center-rods turtles in-radius 0
    set surround-rods turtles in-radius 1 who-are-not turtles in-radius 0
    set min-value-E (max-pycor * max-pxcor * receptive-field) ; for stars setting only, minimum error for plotting and optimizing AP threshold
    set min-value-P (max-pycor * max-pxcor * receptive-field)
    set erlang-poisson-spontaneous-release-rate (2 * erlang-factor / length unitary-vesicle-history) ;coded to match basal release rate of unitary vesicles in poisson model for comparison (Hays et al., 2021)
    set poisson-multiplier 1
    set surround-center-ratio (count turtles in-radius surround-radius who-are-not turtles in-radius center-radius / count turtles in-radius center-radius) ; see above
  ]
  if image = "stars" [ ask turtles [set size 1.1]] ; smaller turtles make it easier to see actual stars behind
  reset-ticks
end


to go
  ask turtles [set index-position (ticks) mod length unitary-vesicle-history]
  ifelse cells = "none" [ask turtles [set color pcolor]] ; shows users the background image behind cells
  [
    ifelse model = "erlang"
    [
      ;line below resets minimum error if it has decreased
      if count turtles with [color = pink AND pcolor = black] + count turtles with [color = black AND pcolor = white]  < min-value-E [ set min-value-E count turtles with [color = pink AND pcolor = black] + count turtles with [color = black AND pcolor = white]]
      ask turtles
      [
        set erlang-counter erlang-counter + random-poisson erlang-poisson-spontaneous-release-rate ;poisson event that adds to erlang event
        ifelse erlang-counter >= erlang-factor ; erlang event
        [
          set multivesicle-history replace-item index-position multivesicle-history multivesicular-number ;adds to multivesicular release history
          set erlang-counter erlang-counter - erlang-factor ;leaves remaining "leftover" events
        ]
        [set multivesicle-history replace-item index-position multivesicle-history 0] ;replaces index with 0 if no erlang event, this is unlike Poisson model where mean poisson variable is decreased to 25% based on membrane potential of rods (Hays et al., 2021)
        ifelse pcolor * random-poisson (photons-per-second / length unitary-vesicle-history) >= 5 ;poisson event that determines if photon hits rod and is absorbed, normalized to make brighter colors have higher mean release rates 5 is the netlogo value between black and white

        [set erlang-poisson-spontaneous-release-rate 0] ; inhibits poisson event during next tick
        [set erlang-poisson-spontaneous-release-rate 2 * erlang-factor / length unitary-vesicle-history] ; resets poisson release rate after inhibition

        ifelse cells = "rods only" [set color (9.9 - (item index-position multivesicle-history) * arbitrary-gradient-enhancer)] ;reflects instantaneous number of vesicle released, but opposite so that lowest number is brightest
        [
          set vesicle-sum sum multivesicle-history ; when bipolar cells shown, vesicles released in bipolar cell's "memory"
          set synapse-strength abs((surround-center-ratio * sum [vesicle-sum] of center-rods) - sum [vesicle-sum] of surround-rods) ;the the sums on center rods are normalized against surround rods (increasing weight of center rods) (Dacey et al., 2000) and the difference between the sums is the synapse strength
          ifelse cells = "bipolar cells only"
          ;graded bipolar is the most accurate representation of bipolar cell activity, but the using the potential threshold in the ungraded bipolar mode is useful for visualizing only bipolar cells which are firing above a certain rate
          [ifelse graded-bipolar? = True [set color 139.9 - (synapse-strength * arbitrary-gradient-enhancer)] [ifelse synapse-strength > potential-threshold [set color pink][set color black]]]
          [
            set color (9.9 - (item index-position multivesicle-history) * arbitrary-gradient-enhancer)
            ifelse graded-bipolar? = True [set color 139.9 - (synapse-strength  * arbitrary-gradient-enhancer)] [if synapse-strength > potential-threshold [set color pink]]
          ]
    ]]]

    [
      ;line below resets minimum error if it has decreased
      if count turtles with [color = pink AND pcolor = black] + count turtles with [color = black AND pcolor = white]  < min-value-P [ set min-value-P count turtles with [color = pink AND pcolor = black] + count turtles with [color = black AND pcolor = white]]
      ask turtles
      [
        set unitary-vesicle-history replace-item index-position unitary-vesicle-history random-poisson (basal-vesicle-release-per-second * poisson-multiplier / length unitary-vesicle-history) ;unitary vesicle release amount added to history
        ifelse pcolor * random-poisson (photons-per-second / length unitary-vesicle-history) >= 5 [set poisson-multiplier 0.25][set poisson-multiplier 1] ;when inhibited, mean poisson rate is decreased to 25% (Hays et al., 2021) 5 is the netlogo value between black and white


        ifelse cells = "rods only"
        [set color (9.9 - (item index-position unitary-vesicle-history * arbitrary-gradient-enhancer)) ]  ;reflects instantaneous number of vesicle released, but opposite so that lowest number is brightest
        [
          set vesicle-sum sum unitary-vesicle-history
          set synapse-strength abs((surround-center-ratio * sum [vesicle-sum] of center-rods) - sum [vesicle-sum] of surround-rods) ;the the sums on center rods are normalized against surround rods (increasing weight of center rods) (Dacey et al., 2000) and the difference between the sums is the synapse strength

          ifelse cells = "bipolar cells only"
          ;graded bipolar is the most accurate representation of bipolar cell activity, but the using the potential threshold in the ungraded bipolar mode is useful for visualizing only bipolar cells which are firing above a certain rate
          [ifelse graded-bipolar? = True [set color 139.9 - (synapse-strength * arbitrary-gradient-enhancer) ] [ifelse synapse-strength > potential-threshold [set color pink][set color black]]]

          [
            set color (9.9 - (item index-position unitary-vesicle-history * arbitrary-gradient-enhancer))
            ifelse graded-bipolar? = True [set color 139.9 - (synapse-strength * arbitrary-gradient-enhancer)] [if synapse-strength > potential-threshold [set color pink]]
          ]
  ]]]]

  if min-value-P > 0 [output-show min-value-E / min-value-P]
tick
end



to clear-plots
  clear-all-plots
  if model = "erlang" [set min-value-E (max-pycor * max-pxcor)] ; minimum error of current model only reset, allows for comparison after reseting the plots to omit transition values from scale, see plot code
  if model = "poisson" [set min-value-P (max-pycor * max-pxcor)]
  set x-counter (ticks) ;see plot code
  clear-output
end
@#$#@#$#@
GRAPHICS-WINDOW
72
265
685
679
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
120
0
80
0
0
1
ticks
40.0

BUTTON
94
53
311
112
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

BUTTON
95
115
310
176
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
338
36
692
69
photons-per-second
photons-per-second
0.1
50
10.8
.1
1
NIL
HORIZONTAL

SLIDER
339
72
693
105
basal-vesicle-release-per-second
basal-vesicle-release-per-second
1
120
120.0
1
1
NIL
HORIZONTAL

CHOOSER
338
108
550
153
cells
cells
"rods only" "bipolar cells only" "both" "none"
1

CHOOSER
96
181
310
226
model
model
"erlang" "poisson"
0

SLIDER
339
157
555
190
potential-threshold
potential-threshold
0
1000
85.0
1
1
NIL
HORIZONTAL

CHOOSER
556
145
693
190
image
image
"custom" "stars"
0

PLOT
721
266
1318
469
Stars - Number of Errors
NIL
NIL
0.0
1.0
10.0
100.0
true
false
"" "    if min-value-E < (max-pycor * max-pxcor) [\n    create-temporary-plot-pen \"temp1\"\n    set-plot-pen-color red\n    plot-pen-down\n    plotxy (ticks - x-counter) min-value-E\n    ]\n    if min-value-P < (max-pycor * max-pxcor) [\n    create-temporary-plot-pen \"temp2\"\n    set-plot-pen-color blue\n    plot-pen-down\n    plotxy (ticks - x-counter) min-value-P\n    ]\n      if image = \"stars\" [\n    create-temporary-plot-pen \"temp\"\n    set-plot-pen-color 7 \n      plot-pen-up\n      plotxy 0 (number-of-stars * receptive-field)\n      plot-pen-down\n      plotxy plot-x-max (number-of-stars * receptive-field)\n    ]"
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [color = pink AND pcolor = black] + count turtles with [color = black AND pcolor = white] "

SWITCH
556
109
694
142
graded-bipolar?
graded-bipolar?
1
1
-1000

BUTTON
958
67
1093
100
NIL
clear-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
717
478
1309
680
Potential Threshold of Bipolar Cells
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot potential-threshold"

PLOT
724
133
1313
253
Bipolar Synapses
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [color = pink]"

INPUTBOX
339
194
690
263
file-path
/Users/carahall/Desktop/so scary.jpg
1
0
String

SLIDER
261
683
503
716
arbitrary-gradient-enhancer
arbitrary-gradient-enhancer
0.0001
.4
0.0353
.0001
1
NIL
HORIZONTAL

OUTPUT
1330
298
1465
402
13

TEXTBOX
1337
269
1487
297
Minimum Error Erlang / Minimum Error Poisson
11
0.0
1

@#$#@#$#@
# CONTEXT
Vision is thought to have evolved over 1,500 separate times in the animal kingdom (learn.genetics.utah.edu). But, despite its universality, the mechanisms which translate the light around us into a complex, dynamic visual perception are still not fully understood, and new mysteries about it are discovered all the time. 
Like with every aspect of an animal’s fitness, the eye is subject to intense selective pressures. Constantly improving the visible spectrum, visible distance, and depth perception, are just a handful of ways animals gain an edge against their competitors (Nilsson, 2009). Likewise, increasing the sensitivity of light receptors to be able to perceive incredibly slight differences in levels of light  — even to its physical limit —  is a process by which organisms improve the accuracy and speed of their responses to visual stimuli. The theory that vertebrate eyes could reliably respond to single photons was proven by a study which demonstrated exactly that in frog rod cells (Baylor, et al., 1984). 
To understand why this is so fascinating, the anatomy of the eye must first be understood. When light enters the eye it hits the retina in the back which is composed of several cell types. The receptor cells are rods and cones, specialized for general light perception and color perception, respectively. The rods are far more sensitive in dim light and thus will be the subject of our look into visual perception in low light. Rod cells have about 108 rhodopsins (book.bionumbers.org), a chromoprotein which transmits a chemical signal when retinal, its ligand, has its conformation changed by light absorption. This triggers a chain of protein activations that ultimately leads to the closing of Na+ channels and the polarization of the cell. At the terminal of the cell, where there would normally be a baseline level of glutamate (neurotransmitter) release by vesicles, it is paused by the change in membrane potential, communicating to bipolar cells, next in the pathway, that light has been detected. The activated bipolar cells then signal the intensity of the visual signal that has been received to their successors, the ganglion cells, which form the optic nerve, the highway to the visual cortex. There, visual information is processed (Tsuchitani, 2020). 
This description lacks an important element of visual processing, edge-detection. Rather than signal every input of light stimulus, and its specific intensity, bipolar cells are designed to be most activated when detecting high amounts of contrast. “On-center” bipolar cells are specialized to detect light surrounded by darkness, and “off-center” bipolar cells for the opposite. When in uniform light or darkness, bipolar cells are laterally inhibited by horizontal cells, activated by neighboring rods. This has the effect of enhancing contrast and omitting uniformity from visual input, before the signal has even left the eye (Tsuchitani, 2020, image via Perlman et al., 2012). 
The details and numbers are critical to the question of whether a single photon could pause vesicle release in the terminal of the rod, then through the bipolar cells, to the ganglion cells. The mean amount of basal vesicle release in the terminal is about 10-20 per second.. Depolarization of the cell by Na+ channel opening lasts about 0.3 seconds (Campbell and Westheimer, 1960), which decreases vesicle release. If one of the 15-30 center  rods connected to a single bipolar cell has a decrease in glutamate release, the bipolar cell is activated, but not if enough surrounding rods inhibit it (Kolb, 2011). The relative strength and area of the surround/center regions can be described by the surround/center gain ratio of about 1, and diameter ratio of about 9. The gain ratio of 1 means that if the total activation of the surrounding cells is equivalent to the center cells, the bipolar cell they are connected to (either directly or laterally through horizontal cells) will be inhibited (Dacey et al., 2000).
In single photon reception, the decrease in vesicle release by one rhodopsin activation must be substantial enough to not mimic normal gaps in vesicle release due to the randomness of Poisson processes. However, the line drawn between “light” and “no light” cannot be so high that coincidentally high amounts of vesicle release accidentally trigger a false positive. To achieve this delicate balance, the authors of  my primary paper, “Properties of multivesicular release from mouse rod photoreceptors support transmission of single-photon responses” speculate 100 vesicles per second would be required to reliably tell the difference between “light” and “no light”. However, this does not reflect reality and would be extremely energetically costly  (Hays et al., 2021). 
A second problem with single photon reception that I considered applies when continuously looking at an image in low light for an extended period of time. If something emitted photons that hit rods on average once per second, it wouldn’t be at  regular intervals. They too follow a Poisson distribution, which adds another source of error, false positives where no light can be detected between photons. There is also a chance that the photon that hits a rod will not be absorbed, but due to the number of rhodopsin on a rod, the chance it will be absorbed is approximately 0.6 (Denny and Gaines, 2000)
. In order to attain a fluctuation rate 3-4 times smaller than other single molecule signals (Field and Rieke, 2002), while still keeping vesicle numbers low, the authors of my focal study propose a more regular release process, facilitated by a ribbon-style synapses. These structures line up several vesicles together and release them after a certain number of Poisson intervals (~6.2), and this is known as an Erlang process. Independent  Poisson vesicle release is still maintained in addition to the multivesicular  release of ~17, on average twice a second. The onset of a pause of this regular process from a rhodopsin activation is far more discernible due to its basal regularity, and thus the process is highly amenable to single photon detection. For the sake of comparison, the authors of my focal study increase the basal unitary vesicle release to 34, and my model follows suit  (Hays et al., 2021). 

# MODEL PURPOSE

The purpose of my model is to allow a user to engage with a model of the rod and bipolar cell layers of the visual processing, while customizing the variables I described previously. I hoped to make a model that worked at higher light levels to demonstrate the edge-detection system. At lower light levels, the difference between the Poisson and Erlang model would be more pronounced. My model would show the accuracy of looking at pinpoints of light, stars, which are the most realistic examples of low light image simulation. But I also hoped to include black and white images of animals, which better show the difference in accuracy by how much the light being signals looks like the image it is detecting. However, it’s important to emphasize that the rods and cones on the retina are only the beginning of the process of visual interpretation, and their output by no means reflects what an animal would “see” when looking at these images. Regardless, their accuracy relates to the accuracy of the final image processed by the brain. 

# MODEL INFORMATION

## VARIABLES

I have created an index of each input of my model and its corresponding code. 
The first thing to understand about the model is that the color of each turtle can either represent a rod or a bipolar cell. Each bipolar cell has its own center receptive field and surround receptive field, but unlike reality, the fields overlap so a rod is a center rod for one bipolar cell but a surround rod for 4. Additionally, there is no distinction between “off-center” and “on-center” bipolar cells because an absolute value operation is used to determine net contrast. The model has the total rods connected at 25, but the actual range for number of  rod connections is ~ 15 - 30 (Kolb, 2011). The model ratio of surround rods to center rods is 4:1, but this is more like 9:1 in reality (Dacey et al., 2000). These changes should not alter the fundamental properties of bipolar cell - rod connections.  The turtle (rod) objects that keep track of the Erlang process and Poisson process are each a list of length three which are filled with numbers that correspond to the number of vesicles released by a normal basal release rate (Poisson) and ribbon synapses. The list is cycled through so that after three ticks, the first input is replaced. This represents the “memory” of the bipolar, the amount of time that a momentary Glutamate concentration (ie number of vesicles released at that time) has an effect on its ability to trigger an action potential. This number is what the authors of “Chance in Biology” suggest is a reasonable standard of time for a cell to “wait” before deciding on the presence of a photon. For the Poisson model, it’s just the output of a random Poisson variable with mu = “basal-vesicle-release-per-second” (5) divided by 3 (each tick corresponds to a third of a second). The mu for the Poisson random variable is decreased to 0.25 * “basal-vesicle-release-per-second” (5) (Hays et al., 2021) for ⅓ of a second after photon absorption (Campbell and Westheimer, 1960), using the poisson-multiplier variable. 
The Erlang vesicle list is filled with only 17s after a Poisson random variable with mean 6.2 * 2 / 3 (to achieve an average of 2 multivesicular releases per second)  has reached a total of 6.2. Then, the multi vesicle release list would be filled with a 17. Inhibition by a photon decreases the mean Poisson random variable all the way to 0 (Hays et al., 2021)
The user picks an image, either “stars” or “custom” by clicking the image dropdown input (9). “Stars” corresponds to a version of the world where 40 random patches (which represent the light coming from the real world) become stars and turn white.
Custom corresponds to an image imported by the code given the file path typed into file-path (10). This image should be black and white, 3 x 2 ratio and have some areas of high contrast. The image I provide the user to download is of a viperfish, and when it is uploaded it appears like this. 
The image is loaded in and all initial variables are reset when the user clicks “Setup” (1). Before or after clicking “go” (2), the user can change which layer of cells they want to see by changing the “cells” variable (6). 
 In the “stars” version of the world, each white patch emits a photon at the same rate, but in the custom, the rate of photon  release is multiplied by the pcolor, so the brightest spots release photons most frequently. The rate of photons hitting the rods and being absorbed are combined into one event. In reality, 60% of photons hitting the rod would be absorbed, but absorption rates can be adjusted by the same slider as emission rates (4). 
Success and failure in the conditional above leads to two different outcomes depending on which model (3) is clicked. 
In the poisson model, a photon absorption leads to a 75% decrease in the mean Poisson variable based on the effect it has on the membrane potential of rods. In the Erlang model, on the other hand, multi vesicle release is so sensitive that a single photon absorption leads to an appreciable pause in Poisson events (Hays et al., 2021). In my model, I excluded unitary vesicle release in the Erlang model cells, which does not reflect reality where unitary vesicle release would still occur in these cells, but I am hoping to demonstrate the differences between these models when they are isolated. 

After “go,” if  “rods only” is clicked, the user sees a field of white at varying brightness levels. The brightness of the white corresponds to the opposite of the number of vesicles being released, since vesicles act as inhibitors. If “bipolar cells only” is clicked, there are two possible visuals of bipolar activity (6). Graded is more realistic because bipolar cells do not have a synaptic threshold for firing, they simply transmit the sum of their center and surrounding synapses, a large signal corresponding to a high contrast. For model usefulness, users can adjust an arbitrary gradient enhancer (12) to better visualize the difference between the most and least strong bipolar signals. Similarly, the user can turn off “graded-bipolar” (6) and set an arbitrary threshold (9)  for the number of net synapses required to see the bipolar neuron. This is useful for exaggerating the difference between the strongest and weakest bipolar signals and comparison between the Poisson and Erlang model. 

## PLOTS

The plots are useful for interpreting the visual differences between the Poisson and Erlang model at different settings in a more quantitative way. Because of the need for a success/failure binary, the bottom two plots (15,16) are only useful for describing the accuracy of the “stars” version with the ungraded bipolar cells. In the “Stars - Number of Errors” plot, the number of incorrectly colored bipolar cells is plotted as well as a black horizontal line marking the number of stars * turtles per star (the number of error if no bipolar cells are colored), the continuously updated minimum for each of the models (blue for Poisson, red for Erlang) which resets with the clear-plots button (13), for the current model. This is useful for comparing the minimum error achievable for each model type because it allows for resetting the plots to omit high transition values from the y-scale. The potential threshold at each time the minimum value is set can be found in the plot below (16) and the ratio for the minimum number of errors for each model E/P is outputted to the right (16), The plot on top (14) shows the number of bipolar synapses (colored bipolar cells) at any given moment, useful for comparing the fuzziness of each model with the same number of colored turtles. 

# DEMONSTRATIONS

Put the file path of the image I provided in the “file-path” input variable. Choose the “erlang” model, 1 photon per second, 100 “basal-vesicle-release-per-second,” graded-potential? off, “none” for cells, and “custom” for image. Then, click “setup” and “go.” 
You should see the background image of a viperfish. Note where the areas of highest contrast are. Then, change the cells to “bipolar cells only”. After a few seconds, adjust the membrane-potential slider so that it is the sharpest version of the fish possible without noise. Then change to the poisson model and again find the sharpest image. They don’t appear to be too different.
100 vesicles per second is too high and unrealistic, so change that variable to 34. Adjust the threshold slider as necessary. Now the sharpest image is much fuzzier. Change the model to “erlang” and adjust, it’s much sharper now!
At low light levels, the Erlang process could maintain image sharpness while keeping vesicle release low. 
Do the same comparison with graded-bipolar? = on, adjusting the gradient enhancer as necessary. 

Change the image to “stars,” graded-bipolar? off, cells “bipolar cells only”, 1 photon per second, 34 basal vesicle release per second, and “poisson” model. Click “setup” and “go.” Adjust the potential threshold so that you see pink dots, and then try to make the line in the middle plot on the right go down as far as possible by fine-tuning the threshold. The red line represents the minimum errors  achieved so far, and the line in the plot below at that gives  the potential threshold for each x-value, if you want to find the minimum again. Once you have your minimum, switch the model to “poisson,” adjust the threshold so the errors are closer to zero, then click “clear-plot.” The red line for the minimum Erlang errors stays, but the blue line for minimum Poisson errors and everything else is cleared. The opposite is true if you go back to Erlang and reset. Find the minimum Poisson errors and compare the lines. The blue line should be quite a bit higher, and the output on the right shows the ratio of the minimum Erlang errors to minimum Poisson errors.
Other things to try
difference between models at high vs low photon frequencies and basal vesicle release rates. 
Your own images!
Looking at rod cells and both cell types together


# CREDITS AND REFERENCES

Baylor DA, Nunn BJ, Schnapf JL. (1984), The photocurrent, noise and spectral sensitivity
of rods of the monkey Macaca fascicularis. The Journal of Physiology.
1984;357:575–607.doi: 10.1113/jphysiol.1984.sp015518.

Campbell, F. W., & Westheimer, G. (1960). Dynamics of accommodation responses of
the human eye. The Journal of Physiology, 151(2), 285–295.
https://doi.org/10.1113/jphysiol.1960.sp006438

Cell Biology by Numbers. (n.d.). How many rhodopsin molecules are in a rod cell?.
https://book.bionumbers.org/how-many-rhodopsin-molecules-are-in-a-rod-cell/

Dacey, D., Packer, O. S., Diller, L., Brainard, D., Peterson, B., & Lee, B. (2000). Center
surround receptive field structure of cone bipolar cells in primate retina. Vision
Research, 40(14), 1801–1811. https://doi.org/10.1016/s0042-6989(00)00039-0 

Denny, M., & Gaines, S. (2011). Chance in biology: Using probability to explore nature.
Princeton University Press. 

Field, G. D., & Rieke, F. (2002). Mechanisms regulating variability of the single photon
responses of mammalian rod photoreceptors. Neuron, 35(4), 733–747.
https://doi.org/10.1016/s0896-6273(02)00822-x 

Hays, C. L., Sladek, A. L., Field, G. D., & Thoreson, W. B. (2021). Properties of
multivesicular release from mouse rod photoreceptors support transmission of
single-photon responses. eLife, 10, e67446. https://doi.org/10.7554/eLife.67446

Kolb, H. (2011.). Circuitry for Rod Signals Through the Retina. WebVision.
https://webvision.med.utah.edu/book/part-iii-retinal-circuits/circuitry-for-rod-cells-
hrough-the-retina/ 

Learn.Genetics.utah.edu. (n.d.). Eye Evolution.
https://learn.genetics.utah.edu/content/senses/eye/#:~:text=550%20million%20years%2
have%20passed,evolved%20more%20than%201%2C500%20times. 

Nilsson, D.-E. (2009). The evolution of eyes and visually guided behaviour.
Philosophical Transactions of the Royal Society of London, Biological Sciences,
364(1531), 2833-2847. doi:10.1098/rstb.2009.0083

Perlman, I., Kolb, H., & Nelson, R. (2012). S-potentials and horizontal cells by Ido Perlman,
Helga Kolb and Ralph Nelson. Webvision.
https://webvision.med.utah.edu/book/part-v-phototransduction-in-rods-and-cones/horizo
tal-cells/ 

Tsuchitani, C. (2020, October 7). Visual processing: Eye and retina (section 2, Chapter 14)
neuroscience online: An electronic textbook for the Neurosciences: Department of
Neuro biologyand Anatomy - the University of Texas Medical School at Houston. Visual
Processing: Eye and Retina (Section 2, Chapter 14) Neuroscience Online: An Electronic
Textbook for the Neurosciences | Department of Neurobiology and Anatomy - The
University of Texas Medical School at Houston.
https://nba.uth.tmc.edu/neuroscience/m/s2/chapter14.html#:~:text=It%20is%20the%20a
ons%20of,other%20diencephalic%20and%20midbrain%20structures. 
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
