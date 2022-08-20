Config = {
    Debug = true, -- Turn debug on / off
    Multiplier = 5, --The Ammount the total lottery pay out will be, based off total value tickets are sold
    TicketValue = 5000, --- The value the database goes up everytime a ticket is submitted. Best practice to use what the sales price you sell the tickets in stores for
    Webhook = "https://discord.com/api/webhooks/1008891845578862642/s-E7IX9Se27-oEqQlniVLLfJVo0Bb0hOybHcu1oPBPEGU7y19S9pZJNLXq0tJZiWYZeq", --Webhook for announcing Lotto Pot Value everytime its updated
    WinHook = "https://discord.com/api/webhooks/1008891845578862642/s-E7IX9Se27-oEqQlniVLLfJVo0Bb0hOybHcu1oPBPEGU7y19S9pZJNLXq0tJZiWYZeq", -- Webhook for where the winner will be posted
    DrawDay = 6, -- weekday the draw will be done, 1=sunday, 2 monday, 3 tuesday, 4 wednesday, 5 thursday, 6 friday, 7 saturday
    DrawTime = 19,--The hour it will be drawn at, 24HR Clock
    AlwaysNotify = true, -- Should the server post new pot every ticket submission? if false, itll only post on server restart
    Command = 'lotterydraw', -- The command to force a lottery draw
    Retries = 5, -- How many times will server retry to find online player before carrying over draw to next draw date 
}   

---------------------------------- READ THE README FILE FOR SETUP INSTRUCTIONS -----------------------------------------