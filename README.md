
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
