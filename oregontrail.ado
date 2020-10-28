*===============================================================================
* FILE: oregontrail.ado
* PURPOSE: Plays Oregon Trail (based off 1978 version) in Stata
* SEE: github.com/mdroste/stata-oregontrail
* JUST A PORT OF: github.com/philjonas/oregon-trail-1978-python
*===============================================================================

program define oregontrail
	version 12.1
	
	syntax [anything], [test] 
	set more off
	
	* Define some local times
	global time1 1000
	global time2 1500
	global time3 2000
	
	* Display intro ASCII art
	oregontrail_display_intro
	
	* Reset globals
	capture macro drop ot*
	
	
	* Initialize macros
	oregontrail_initialize_macros
	
	* Prompt for begin
	oregontrail_menu_main	
	
	* Ending
	if "${ot_menu_main_ans}"=="0" {
		di "Quitting now."
		exit
	}
		
	* Set marksman level
	oregontrail_marksman_level
		
	* Set spending on oxen, food, ammo, clothing, and misc
	oregontrail_oxen
	oregontrail_general_expenses food
	oregontrail_general_expenses ammo
	oregontrail_general_expenses clothing
	oregontrail_general_expenses misc
		
	* Main loop
	oregontrail_main_loop
	

	
end

*===============================================================================
* Helper functions
*===============================================================================

*---------------------------------------------------
* Helper: Display intro
*---------------------------------------------------

program define oregontrail_display_intro
	version 12.1
	
	di as text ""
	di "                             `./////////:...            `....-/////:`  "
	di "                             -oo:/oooooooooo++/`:++++..+oooooooooooo/  "
	di "                              /+``/ooooooooooo/.ooooo+.oooooooooooo+.  "
	di "                               o/  `+ooooooooo/.ooooo+.oooooooooooo.   "
	di "                               .o-  -ooooooooo/.ooooo+.ooooooooooo:    "
	di "    --.  -+.                    :o-  +oooooooo/.ooooo+.oooooooooo:     "
	di "     .+oooo::+oo/::::::::`      `+-  +oooooooo/.ooooo+.oooooooooo`     "
	di "   `/+oooooooooooooooooooo-     `:...::..-:::..-::::::-:-..:::-.-`     "
	di "    ```-::/ooooooooooooooo/------:+oo.`:/./o:-/:/ooooo/`./-.o+://`     "
	di "         -:ooooooo++oooo+.      `+o-  +---/o.`.:. /o+  -/.``o+----     "
	di "          `oooo/.. `:o+o+         ``  /:` :o-.:-` ...  ./:--o/ `:-     "
	di "         .++-`/o`  .:+:++              ./:/o//:`        `-/-oo+/.      "
	di "          _____                              _____         _ _          "
	di "         |  _  |                            |_   _|       (_) |         "
	di "         | | | |_ __ ___  __ _  ___  _ __     | |_ __ __ _ _| |         "
	di "         | | | | `__/ _ \/ _` |/ _ \| `_ \    | | `__/ _` | | |         "
	di "         \ \_/ / | |  __/ (_| | (_) | | | |   | | | | (_| | | |         "
	di "          \___/|_|  \___|\__, |\___/|_| |_|   \_/_|  \__,_|_|_|         "
	di "                          __/ |                                         "                 
	di "                         |___/       " _continue
	sleep ${time1}
	di " in Stata"
	sleep ${time1}
    di ""
	di "This program simulates a trip over the Oregon Trail from Independence, MO to "
	di "  Oregon City, OR in 1847. Your family of five will cover the 2040-mile "
	di "  Oregon Trail in 5-6 months -- if you make it alive."
	sleep ${time2}
    di ""
	di "You saved $900 to spend for the trip, and you've just paid $200 for a wagon."
    di "You will need to spend the rest of your money on the following items:"
    di "  - Oxen: The more you spend, the faster you'll go."
    di "  - Food: Eating more reduces your chance of getting sick."
    di "  - Ammunition: Needed for hunting and defense against attacks."
    di "  - Clothing: Keeps you warm in cold weather, especially in mountains."
    di "  - Misc. Supplies: Includes medicine and materials for emergency repairs."
	sleep ${time3}
    di ""
    di "You can spend all your money before you start your trip, or spend some at "
	di "  forts along the way. Additional food can also be obtained by hunting."
	sleep ${time2}
    di ""
    di "Good luck!"
    di ""
	sleep ${time1}
	
end

*---------------------------------------------------
* Helper: Get input for main menu
*---------------------------------------------------

program define oregontrail_menu_main
	version 12.1
	
	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
		
		* Prompt
		di as text "Enter 0 quit."
		di "Enter 1 to begin."
		di "" _request(ot_ans)
			
		* Exception handling: see if user input is valid
		if ~inlist("${ot_ans}","0","1") {
			di "Error: valid options are 0 (quit) and 1 (begin game). Try again."
		}
		
		* If valid input, exit the while loop and pass input to global
		else {
			local valid_response = 1
			global ot_menu_main_ans = ${ot_ans}
		}
	}

end

*---------------------------------------------------
* Helper: Initialize macros
*---------------------------------------------------

program define oregontrail_initialize_macros
	version 12.1
	
	* Flag for alive or dead
	global ot_dead     = 0
	
	* Flag for quitting
	global ot_quit 	   = 0
	
	* Flag for winning
	global ot_win      = 0
	
	* Shooting level
	global ot_marksman = 0
	
    * Turn number for setting date
    global ot_current_date = 1
	
    * Total mileage, whole trip
    global ot_total_mileage = 0
	
	* Keep track of cash and spending
	global ot_cash     = 700
	if "`test'"!="" global ot_cash = 2000
	global ot_oxen     = 0
	global ot_food     = 0
	global ot_ammo     = 0
	global ot_clothing = 0
	global ot_misc     = 0
	
	
	* Flag for goal distance in miles
	global ot_goal_in_miles       = 2040
	
	* Flag for south pass distance in miles
	global ot_south_pass_in_miles = 950
	
	* Flag for insufficient clothing in cold weather
    global ot_is_sufficient_clothing = 0
    * Choice of eating
    global ot_choice_of_eating = 1
    * Flag for clearing south pass
    global ot_has_cleared_south_pass = 0
    * Flag for clearing blue mountains
    global ot_has_cleared_blue_montains = 0
    * Fraction of 2 weeks traveled on final turn
    global ot_fraction_of_2_weeks = 0
    * Flag for injury
    global ot_is_injured = 0
    * Flag for blizzard
    global ot_is_blizzard = 0
    * Total mileage through previous turn
    global ot_total_mileage_previous_turn = 0
    * Flag for illness
    global ot_has_illness = 0
    * Hostility of riders factor
    global ot_hostility_of_riders = 0
	
end

*---------------------------------------------------
* Helper: Get marksman level
*---------------------------------------------------

program define oregontrail_marksman_level
	version 12.1
		
	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
	
	di as text " "
	di "How good a shoto are you with your hunting rifle?"
	di "  1. Ace marksman"
	di "  2. Good shot"
	di "  3. Fair to middlin'"
	di "  4. Need more practice"
	di "  5. Shaky knees"
	di "Enter a number from 1 to 5."
	di "" _request(ot_ans)
	
		* Exception handling: see if user input is valid
		if ~inlist(${ot_ans},1,2,3,4,5) {
			di "Error. Choose a number between 1 and 5."
		}
		
		* If valid input, exit the while loop and pass input to global
		else {
			local valid_response = 1
			global ot_shooting_level = ${ot_ans}
		}
		
	}
	
end

*---------------------------------------------------
* Helper: Get oxen
*---------------------------------------------------

program define oregontrail_oxen
	version 12.1
	
	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
		
	sleep 800
	di as text " "
	di "How much do you want to spend on your oxen team?"
	di "Enter an amount between 200 and 300."
	di "" _request(ot_ans)
	
		* Exception handling: see if user input is valid
		if ~inrange(${ot_ans},200,300) {
			di as text "Error. You can only spend between $200 and $300 on oxen."
		}
		
		* If valid input, exit the while loop and pass input to global
		else {
			local valid_response = 1
			global ot_oxen = ${ot_ans}
			global ot_cash = ${ot_cash} - ${ot_oxen}
			local amt = ${ot_oxen}
			local amt2 = ${ot_cash}
			di as text "You spend $`amt' on oxen and have $`amt2' remaining."
		}
		
	}
	
end

*---------------------------------------------------
* Helper: Expenses for food, ammo, clothing
*---------------------------------------------------

program define oregontrail_general_expenses
	version 12.1
	syntax [anything]
	local category `anything'
	
	* Ad hoc formatting for misc supplies
	local category_f `category'
	if "`category'"=="misc" local category_f = "misc. supplies"
	if "`category'"=="ammo" local category_f = "ammunition"

	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
		
	sleep ${time1}
	di as text " "
	di "How much do you want to spend on `category_f'?"
	di "" _request(ot_ans)
	
		* Exception handling: see if user input is valid
		if ~inrange(${ot_ans},0,${ot_cash}) {
			local curr = ${ot_cash}
			di as text "Error. You can only spend between $0 and $`curr' on `category_f'."
		}
		
		* If valid input, exit the while loop and pass input to global
		else {
			local valid_response = 1
			global ot_`category' = ${ot_ans}
			global ot_cash = ${ot_cash} - ${ot_`category'}
			local amt = ${ot_`category'}
			local amt2 = ${ot_cash}
			di as text  "You spend $`amt' on `category_f' and have $`amt2' remaining."
		}
		
	}
	
end
	
*---------------------------------------------------
* Helper: Print inventory
*---------------------------------------------------

program define oregontrail_print_inventory
	version 12.1
	
	global date_1 = "March 29"
	global date_2 = "April 12"
	global date_3 = "April 26"
	global date_4 = "May 10"
	global date_5 = "May 24"
	global date_6 = "June 7"
	global date_7 = "June 21"
	global date_8 = "July 5"
	global date_9 = "July 19"
	global date_10 = "August 2"
	global date_11 = "August 16"
	global date_12 = "August 31"
	global date_13 = "September 13"
	global date_14 = "September 27"
	global date_15 = "October 11"
	global date_16 = "October 25"
	global date_17 = "November 8"
	global date_18 = "November 22"
	global date_19 = "December 6"
	global date_20 = "December 20"
	global weekday1 = "Saturday"
	global weekday2 = "Sunday"
	global weekday3 = "Monday"
	global weekday4 = "Tuesday"
	global weekday5 = "Wednesday"
	global weekday6 = "Thursday"
	global weekday7 = "Friday"
	
	local dofw = mod(${ot_current_date},7)+1
	local dofw2 = "${weekday`dofw'}"
	
	* Convert globals to locals for display formatting
	local cash_f = ${ot_cash}
	local oxen_f = ${ot_oxen}
	local food_f = ${ot_food}
	local ammo_f = ${ot_ammo}
	local clothing_f = ${ot_clothing}
	local misc_f = ${ot_misc}
	
	* Distance to go
	local goal_dist = ${ot_goal_in_miles} - ${ot_total_mileage}
	
	* Current state (just for fun)
	local location "Missouri"
	if inrange(${ot_total_mileage},1,400) local location "Kansas"
	if inrange(${ot_total_mileage},400,800) local location "Nebraska"
	if inrange(${ot_total_mileage},800,1200) local location "Wyoming"
	if inrange(${ot_total_mileage},1200,1600) local location "Idaho"
	if inrange(${ot_total_mileage},1600,2200) local location "Oregon"
	
	di ""
	di as text "{hline 80}"
	di in gr "{ul:Trip}" _continue
	di in gr _col(48) "{ul:Resources}"
	di "Date: `dofw2', ${date_${ot_current_date}}, 1847" _continue
	di _col(48) "Cash:           $`cash_f'"
	di "Distance travelled: ${ot_total_mileage} miles" _continue
	di _col(48) "Oxen:           $`oxen_f'"
	di "Location: `location'" _continue
	di _col(48) "Food:           $`food_f'"
	di "Distance to Oregon: `goal_dist' miles" _continue
	di _col(48) "Clothing:       $`clothing_f'"
	di _col(48) "Ammo:           $`ammo_f'"
	di _col(48) "Misc. Supplies: $`misc_f'"
	di as text "{hline 80}"

end

	
*---------------------------------------------------
* Helper: Dates
*---------------------------------------------------

program define oregontrail_get_dates
	version 12.1
	global date_1 = "March 29"
	local date_2 = "April 12"
	local date_3 = "April 26"
	local date_4 = "May 10"
	local date_5 = "May 24"
	local date_6 = "June 7"
	local date_7 = "June 21"
	local date_8 = "July 5"
	local date_9 = "July 19"
	local date_10 = "August 2"
	local date_11 = "August 16"
	local date_12 = "August 31"
	local date_13 = "September 13"
	local date_14 = "September 27"
	local date_15 = "October 11"
	local date_16 = "October 25"
	local date_17 = "November 8"
	local date_18 = "November 22"
	local date_19 = "December 6"
	local date_20 = "December 20"
	local weekday1 = "Saturday"
	local weekday2 = "Sunday"
	local weekday3 = "Monday"
	local weekday4 = "Tuesday"
	local weekday5 = "Wednesday"
	local weekday6 = "Thursday"
	local weekday7 = "Friday"
	
end

*---------------------------------------------------
* Main loop
*---------------------------------------------------

program define oregontrail_main_loop
	version 12.1
	
	* While not dead, not quit, not won
	while ${ot_dead}==0 & ${ot_quit}==0 & ${ot_win}==0 {
	    
		* Start of turn: current distance set to 0
		global ot_curr_dist = 0
		
	    * Print inventory
		oregontrail_print_inventory
		
		* Display food warning if stock low
		if ${ot_food}<13 {
			di as text " "
			di "Your food stock is very low. You should hunt or buy some food immediately."
		}
		
		* Doctor's bill if illness/injured
		if ${ot_has_illness}==1 | ${ot_is_injured}==1 {
		    * If you can't afford to pay it, you die
			if ${ot_cash}<20 {
				di as text " "
			    di "You cannot afford to seek medical attention and die."
				global ot_dead = 1
			}
			else {
				di as text " "
				di "You pay a doctor's bill of $20."
			    global ot_cash = ${ot_cash} - 20
			}
		}
		
		* Get choices: continue, hunt, fort, quit
		oregontrail_get_choices
		if ${ot_quit}==1 exit
		
		* Get food choices
		sleep ${time2}
		oregontrail_get_choices_food
		
		* Riders XX
		*oregontrail_riders
		
		* Random event
		if ${ot_dead}!=1 {
			sleep ${time2}
			oregontrail_get_random_event
		}
		
		* Mountain XX
		
		** Death XX
		*oregontrail_check_death
		
		* If not dead, display move forward info and end of turn
		if ${ot_dead}!=1 {
			*di "DEBUG: curr dist is $ot_curr_dist"
			* Move forward
			global ot_curr_dist = ${ot_curr_dist} + 200 + ceil((${ot_oxen}-220)/5 + runiform()*10) 
		
			* Compute total mileage
			sleep ${time2}
			di as text " "
			di "You travel ${ot_curr_dist} miles this week."
			sleep ${time2}
			global ot_total_mileage = ${ot_total_mileage} + $ot_curr_dist
			global ot_is_blizzard = ${ot_is_sufficient_clothing}==0
			
			* Iterate turn forward
			global ot_current_date = ${ot_current_date}+1
		}
	
		* Set win flag if distance to goal is negative
		global ot_win = ${ot_goal_in_miles} - ${ot_total_mileage} < 0
		    
	}
	
	* Lose condition: Die if current turn is now 21 and havent reached end
	if ${ot_win}==0 & ${ot_current_date}>20 {
		di as text " "
		di "You have been on the trail too long."
		di "Your family dies in the first blizzard of winter."
		global ot_dead = 1
	}
	
	* If dead
	if ${ot_dead}==1 {
		di as text " "
		sleep 1000
	    di "We are sorry you didn't make it to the great territory of Oregon."
		sleep 1000
		di "Better luck next time."
		sleep ${time1}
		di "Sincerely,"
		sleep ${time1}
		di "The Oregon City Chamber of Commerce"
	}
	
	* if win
	if ${ot_win} == 1 {
		di as text " "
		sleep ${time1}
		di "You finally arrived in Oregon City after ${ot_goal_in_miles} long miles! A real pioneer!"
		sleep ${time1}
		di "President James K. Polk sends you his heartiest congratulations"
		di "  and wishes you a prosperous life ahead at your new home."
	}
	
end

*---------------------------------------------------
* Get choices (continue, hunt, fort)
*---------------------------------------------------

program define oregontrail_get_choices
	version 12.1
	
	*------------------------------------------
	* Choices on odd dates: includes forts
	*------------------------------------------
	
	if mod(${ot_current_date},2)==1 {
	    
		* Macro for valid response
		local valid_response = 0
	
		* While loop for valid input
		while `valid_response'==0 {
		    
			* Display options
			di "Do you want to:"
			di "  1. Continue"
			di "  2. Hunt"
			di "  3. Stop at the next fort"
			di "Enter a number from 1 to 3 to choose, or enter 0 to end the game now."
			di "" _request(ot_ans)
			
			* Exception handling: see if user input is valid
			if ~inlist(${ot_ans},0,1,2,3) {
				di as text "Error. Valid options are 1 (continue), 2 (hunt), 3 (fort), or 0 (quit)."
			}
			
			* If past exception handling, exit while loop
			else {
			    local valid_response = 1
			}
		
		}
	}
	
	*------------------------------------------
	* Choices on even dates: no forts
	*------------------------------------------
	
	if mod(${ot_current_date},2)==0 {
	    
		* Macro for valid response
		local valid_response = 0
	
		* While loop for valid input
		while `valid_response'==0 {
		    
			* Display options
			di "Do you want to:"
			di "  1. Continue"
			di "  2. Hunt"
			di "Enter either 1 or 2 to choose, or enter 0 to end the game now."
			di "" _request(ot_ans)
			
			* Exception handling: see if user input is valid
			if ~inlist(${ot_ans},0,1,2) {
				di as text "Error. Valid options are 1 (continue), 2 (hunt), or 0 (quit)."
			}
					
			* If past exception handling, exit while loop
			else {
			    local valid_response = 1
			}
			
		}
		
	}
	
	* Handle choices
	global ot_curr_choice = ${ot_ans}
	if $ot_curr_choice==1 di as text "You chose to continue."
	
	* xx hunting
	if $ot_curr_choice==2 {
	    di as text "You chose to hunt."
		oregontrail_hunt
	}
	
	* xx fort
	if $ot_curr_choice==3 {
	    di as text "You chose to go to the nearest fort."
		oregontrail_fort
	}
	
	* quitting
	if $ot_curr_choice==0 { 
		di as text "You chose to quit the game early. Ending now."
		global ot_quit = 1
	} 
	

end

*---------------------------------------------------
* Get food choices
*---------------------------------------------------

program define oregontrail_get_choices_food
	version 12.1
	
	if ${ot_food} < 13 {
		"You don't have enough food to last through the week. Your party dies of starvation."
		global ot_dead = 1
		exit
	}
	
	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
		
		di as text " "
		di "Do you want to:"
		di "  1. Eat poorly"
		di "  2. Eat moderately well"
		di "  3. Eat well"
		di "Enter a number from 1 to 3 to choose."
		di "" _request(ot_ans)
		
		* Exception handling: see if user input is valid
		if ~inlist(${ot_ans},1,2,3) {
			di as text "Error. Valid options are 1 to 3."
		}
		
		* Exception handling 2: See if user input is valid
		local eaten = (${ot_food}-8) - (5*${ot_ans})
		else if `eaten' < 0 {
		    di as text "Error. You can't eat that well."
		}
		
		* If past exception handling, exit while loop
		else {
			local valid_response = 1
		}
		
	}
	
	* Handle choice
	global ot_choice_of_eating = $ot_ans
	if ${ot_choice_of_eating}==1 di as text "You chose to eat poorly."
	if ${ot_choice_of_eating}==2 di as text "You chose to eat moderately well."
	if ${ot_choice_of_eating}==3 di as text "You chose to eat well."
	global ot_food = (${ot_food}-8) - (5*${ot_choice_of_eating})
	
	

end


*---------------------------------------------------
* Riders
*---------------------------------------------------

program define oregontrail_riders
	version 12.1
	
	* Riders attack
	if runiform()*10 <= ((${ot_total_mileage}/100-4)^2+72) / ((${ot_total_mileage}/100-4)^2+12)-1 {
		local hostility = runiform() < 0.8
		if `hostility'==1 {
			di "Riders ahead - they look hostile."
			if runiform()<0.2 local hostility = runiform() < 0.5
			di "You have four options:"
			di "  1. Run"
			di "  2. Attack"
			di "  3. Continue"
			di "  4. Circle wagons"
			di "What do you choose to do?"
		}
	}
end
	

*---------------------------------------------------
* Hunting
*---------------------------------------------------

program define oregontrail_hunt
	version 12.1
	
	* Can only hunt with more than $39 in ammo
	if ${ot_ammo}<15 {
	    di as text "You don't have enough ammunition to hunt (need at least $15 worth)."
	}
	
	else {
	    
		* Subtract some miles
		sleep 1000
		di as text " "
	    di "Your hunt takes you many miles off the Oregon Trail. "
		sleep 1000
	    global ot_curr_dist = ${ot_curr_dist} - 45
		
		* Choose a random word
	    local r1 = runiform()
		local huntword1 = "bang"
		local huntword2 = "blam"
		local huntword3 = "pow"
		local huntword4 = "wham"
		local r2 = ceil(runiform()*4)
		
		* Prompt user to type random word
		di "An animal appears in front of you!"
		sleep ${time1}
		di "Quickly type `huntword`r2'':"
		timer clear
		timer on 11
		di "" _request(ot_ans)
		timer off 11
		qui timer list
		
		* Save their response time
		local response_time = r(t11)
		local response_time2 = `response_time' - (${ot_shooting_level}-1)
		local response_time3 = max(`response_time2',0)
		*di "response time: `response_time', `response_time2', `response_time3'"
		
		* If typed incorrectly, user misses for sure
		if "${ot_ans}"!="`huntword`r2''" {
		    "You missed! Your dinner escaped."
			global ot_ammo = ${ot_ammo}-10
		}
		
		* Otherwise, outcome depends on time
		else {
		    
		    * If response time (normalized for skill) < 1, user gets it
		    if `response_time3'<=1 {
			    di as text "You got a big one! Full bellies tonight!"
				global ot_food = ${ot_food}+52 + ceil(`r1'*6)
				global ot_ammo = ${ot_ammo}-10 - ceil(`r1'*4)
			}
			
			* Otherwise, depends a bit on luck
			else {
				if 100*`r1' < 13*`response_time3' {
					di as text "You barely missed! Your dinner escaped."
					global ot_ammo = ${ot_ammo}-10
				}
				else {
					di as text "Nice shot! Good eating tonight!"
					global ot_food = ${ot_food}+48 - ceil(2*`response_time')
					global ot_ammo = ${ot_ammo}-10 - ceil(3*`response_time')
				}
			}
		
		}
	}
	
end


*---------------------------------------------------
* Fort dialogue
*---------------------------------------------------

program define oregontrail_fort
	version 12.1
	* Main menu
	
	* Macro for valid response
	local valid_response = 0
	
	* While loop for valid input
	while `valid_response'==0 {
		
		di as text " "
		di "You enter a fort."
		di "Here are your options:"
		di "1. Buy food"
		di "2. Buy oxen"
		di "3. Buy ammunition"
		di "4. Buy clothing"
		di "5. Buy misc. supplies"
		di "0. Exit fort"
		di "Please enter an option 0-5."
		di "" _request(ot_ans)
		
		if ~inlist(${ot_ans},0,1,2,3,4,5) {
			di "Error. Valid options are numbers 0-5. Try again."
		}
		
		* If 0: leave fort
		if ${ot_ans}==0 {
			di as text "You leave the fort."
			local valid_response = 1
		}
		
		* If 1-5: Pass to sub-routine
		if ${ot_cash}<=0 {
			di "You don't have any cash. Type 0 to leave the fort."
		}
		if ${ot_cash}>0 {
			if ${ot_ans}==1 {
				oregontrail_fort_buy food
			}
			else if ${ot_ans}==2 {
				oregontrail_fort_buy oxen
			}
			else if ${ot_ans}==3 {
				oregontrail_fort_buy ammo
			}
			else if ${ot_ans}==4 {
				oregontrail_fort_buy clothing
			}
			else if ${ot_ans}==5 {
				oregontrail_fort_buy misc
			}	
		}
	}
		
end

*---------------------------------------------------
* Fort dialogue
*---------------------------------------------------

program define oregontrail_fort_buy
	version 12.1
	syntax [anything]
	
	local b = "`anything'"
	local b_fmt = "`anything'"
	if "`b'"=="misc" local b_fmt = "misc. supplies"
	if "`b'"=="ammo" local b_fmt = "ammunition"
	
	local valid_response=0
	
	while `valid_response'==0 {
		di as text " "
		di "You choose to buy `b'. How much do you want to spend on `b_fmt'?"
		di "Enter any amount not exceeding your cash on hand (${ot_cash}), or 0 to go back."
		di "" _request(ot_ans2)
		local try = "$ot_ans2"
		local try2 = "$ot_cash"
		if ~inrange(${ot_ans},0,${ot_cash}) {
			di "Error. You tried to purchase $`try' worth of `b_fmt', but you only have $`try2' in cash."
		}
		else {
			di as text "You purchased $`try' worth of `b_fmt'".
			global ot_`b' = ${ot_`b'} + `try'
			global ot_cash = ${ot_cash} - `try'
			local valid_response = 1
		}
	}
	
end

*---------------------------------------------------
* Get random event
*---------------------------------------------------

program define oregontrail_get_random_event
	version 12.1
	
	local event1 weather
	local event2 wagon_break_down
	local event3 ox_injuries
	local event4 arm_broke
	local event5 ox_wander
	local event6 helpful_indians
	local event7 lost_son
	local event8 unsafe_water
	local event9 wagon_fire
	local event10 heavy_fog
	local event11 snake_posion
	local event12 wagon_swamped
	local event13 hail_storm
	local event14 eating
	local event15 animals_attack
	local event16 bandits_attack
	
	local r1 = ceil(runiform()*16)
	
	* Event 1: Weather
	if `r1'==1 {
		di as text " "
		if ${ot_clothing} > 22 + 4*runiform() {
			di "Cold weather! Brrrrrr! You have enough clothing to keep you warm."
		}
		else {
			di "Cold weather! Brrrrrr! You don't have enough clothing to keep you warm."
			di "You die of exposure."
			global ot_dead=1
		}
	}
	
	* Event 2: Wagon breakdown
	if `r1'==2 {
		di as text " "
		di "Heavy rains --- Time and supplies are lost."
		global ot_food = ${ot_food} - 10
		global ot_ammo = ${ot_ammo} - 5
		global ot_misc = ${ot_misc} - 15
		global ot_curr_dist = ${ot_curr_dist} - ceil(10*runiform()) - 5
	}
	
	* Event 3: Ox injuries
	if `r1'==3 {
		di as text " "
		di "An ox injured its leg, slowing you down for the rest of your trip."
		global ot_curr_dist = ${ot_curr_dist} - 25
		global ot_oxen = ${ot_oxen} - 20
	}
	
	* Event 4: Arm broke
	if `r1'==4 {
		di as text " "
		di "Bad luck - your daughter broke her arm."
		di "You had to stop and use supplies to make a sling."
		global ot_curr_dist = ${ot_curr_dist} - 5 - ceil(4*runiform())
		global ot_misc = ${ot_misc} - 2 - ceil(3*runiform())
	}
	
	* Event 5: Ox wander
	if `r1'==5 {
		di as text " "
		di "Your ox wanders off, and you spend time looking for it."
		global ot_curr_dist = ${ot_curr_dist} - 17
	}
	
	* Event 6: Helpful travelers
	if `r1'==6 {
		di as text " "
		di "Helpful travelers show you where to find more food."
		global ot_food = ${ot_food} + 14
	}
	
	* Event 7: Lost son
	if `r1'==7 {
		di as text " "
		di "Your son gets lost, and you spend half the day looking for him."
		global ot_curr_dist = ${ot_curr_dist} - 10
	}
	
	* Event 8: Unsafe water
	if `r1'==8 {
		di as text " "
		di "The water around here is unsafe, and you lose time looking for a clean spring."
		global ot_curr_dist = ${ot_curr_dist} - 2 - ceil(runiform()*10)	
	}
	
	* Event 9: Wagon fire
	if `r1'==9 {
		di as text " "
		di "There was a fire in your wagon! Food and supplies were damaged."
		global ot_curr_dist = ${ot_curr_dist} - 15
		global ot_food = ${ot_food} - 40
		global ot_ammo = ${ot_ammo} - 40
		global ot_misc = ${ot_misc} - 3 - ceil(runiform()*8)
	}
	
	* Event 10: Heavy fog
	if `r1'==10 {
		di as text " "
		di "Your wagon loses its way in heavy fog, slowing your progress."
		global ot_curr_dist = ${ot_curr_dist} - 10 - ceil(runiform()*5)
	}
	
	* Event 11: Snake poison
	if `r1'==11 {
		di as text " "
		di "You kill a venomous snake after it bites you."
		global ot_ammo = max(${ot_ammo} - 5,0)
		global ot_misc = ${ot_misc} - 5
		if ${ot_misc}<0 {
			di "You have no medicine and die from the effects of the snakebite."
			global ot_dead = 1
		}
		
	}
	
	* Event 12: Wagon swamped
	if `r1'==12 {
		di as text " "
		di "Your wagon gets swamped fording a river. You lose food, clothes, and time."
		global ot_food = ${ot_food} - 30
		global ot_clothing = ${ot_clothing} - 20
		global ot_curr_dist = ${ot_curr_dist} - 20 - ceil(runiform()*20)
		
	}
	
	* Event 13: Hail storm
	if `r1'==13 {
		di as text " "
		di "There is a hail storm. Your supplies are damaged."
		global ot_curr_dist = ${ot_curr_dist} - 5 - ceil(runiform()*10)
		global ot_misc = ${ot_misc} - 4 - ceil(runiform()*3)
	}
	
	* Event 14: Eating
	if `r1'==14 {
		local rand_unif = runiform()
		
	}
	
	* Event 15: Animal attack
	if `r1'==15 {
		di as text " "
		di "Wild animals attack!"
		
		* If you have bullets, go on
		if ${ot_ammo}<10 {
			"You were too low on bullets and die in the attack."
			global ot_dead = 1
			exit
		}
		
		else {
					
			* Choose a random word
			local r1 = runiform()
			local huntword1 = "bang"
			local huntword2 = "blam"
			local huntword3 = "pow"
			local huntword4 = "wham"
			local r2 = ceil(runiform()*4)
			
			* Prompt user to type random word
			di "Quickly type `huntword`r2'':"
			timer clear
			timer on 11
			di "" _request(ot_ans)
			timer off 11
			qui timer list
			
			* Save their response time
			local response_time = r(t11)
			local response_time2 = `response_time' - (${ot_shooting_level}-1)
			local response_time3 = max(`response_time2',0)
			*di "response time: `response_time', `response_time2', `response_time3'"
			
			* If typed incorrectly, user misses for sure
			if "${ot_ans}"!="`huntword`r2''" {
				di "Slow on the draw - they got at your food and clothes."
				global ot_food = ${ot_food} - 20
				global ot_clothing = ${ot_clothing} - 15
			}
			
			* Otherwise, outcome depends on time
			else {
				if `response_time3'<=2 {
					di as text "Nice shooting! They didn't get much."
				}
				else {
					di "Slow on the draw - they got at your food and clothes."
					global ot_food = ${ot_food} - ceil(8*`response_time3')
					global ot_clothing = ${ot_clothing} - ceil(4*`response_time3')
					
				}
			}
			
		}

	}
	
	* Event 16: Bandits attack
	if `r1'==16 {
		
	}
	
	
end



program define oregontrail_illness
	version 12.1
	local ot_rand = runiform()
	if 100*`ot_rand' < 10+35*(${ot_choice_of_eating}-1) {
	    di "Mild illness -- medicine used."
		global ot_total_mileage = ${ot_total_mileage} - 5
		global ot_misc = ${ot_misc} - 2
	}
	if 100*`ot_rand' < 100-(40/4^${ot_choice_of_eating}-1) {
	    di "Bad illness -- medicine used."
		global ot_total_mileage = ${ot_total_mileage} - 5
		global ot_misc = ${ot_misc} - 5
	}
	else {
	    di "Serious illness -- you must stop for medical attention."
		global ot_total_mileage = ${ot_total_mileage} - 5
		global ot_has_illness = 1
	}
	
end
