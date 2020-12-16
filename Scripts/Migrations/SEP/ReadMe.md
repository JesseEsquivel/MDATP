# Migrate Symantec Endpoint Protection --> Defender for Endpoint
Migrate your settings from McAfee to Microsoft Defender. :thumbsup:


                                             @@@@@@@@@@@@@@                     
                                          @@#@@@@@@@(//////@@@@                 
                     %@@              @@@. /@@@@@@@((@((@(@@@@@@                
                      @@.@@@   @@@@@@@@@@@@(@@@@@@@@(*@  @@#..(#@               
                        @@..,@//   ////@@@@@#@//////// ,.////////@(             
                          @@,.       //////@@@@@@@///.////@@@@@@@@              
                         &@@            //@@@@@@@@../////@@@@((@@@              
                 @@@@##@@%                 /@@@@#//,....@@@@@@@((@              
             @@@###/./....# @@@@@@     .    .....//////(((((((((@@@@@           
       @@#@@@####//////...#@@@@@@@@    ..    ..//////,...     @/(((///@@@       
    @@ @######///////,/###@@@@@@@@@@         .,///......        ////(((///@@@//@ 
    @#####//######/######@@@@@      ..           ###,....        @@(((/////////@@
    @@@@#####///#//####@@@@@@@                      ##### .         @@@@@(((((((@@  
    &@@@@@@/######@@@@@@@@@   @...@@   @@@@@@@@@@@@@(  @&         @@@@@@@@@@@@@    
     @@@@#&@@%@@@@@@@@@@  @@@..@@@                    @@       ...@@@@@@@@      
         (@@@@@@@@@@@@@@@@@@@@                           (@@*    ...@@@@@       
                                                             @&   @...@@        
                                                               @@    @@         
                                                                 @@@@@@         

## Convert-SEPExclusions.ps1
This script will read in an exported SEP AV exclusion xml, and export the AV exclusions in Microsoft Defender AV format!  It produces two columns in a CSV:

Exclusion                    | Note
| :--- | :---
C:\Program Files\Rock Band\  | Typically there are no notes exported from the xml

Enjoy! :smiling_imp:
