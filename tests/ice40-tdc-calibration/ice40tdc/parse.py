import json

with open("LOG_CW308.txt", "r") as file:
    
    delaydata = [dict() for _ in range(0, 32)]

    line = True
    elements = -1
    while line:
        line = file.readline()

        if line.startswith("Testing"):

            split = line.split("delay_elements")

            elements = int(split[0].split(' ')[1])

            # There is a bug in logwriting currently - this
            # *should* be on next line but isn't, so we fix
            # it here for now.
            line = split[1]
        
        data = line.split(': ')

        if elements > 0:
            if len(data) == 2:
                delaydata[elements][int(data[1].rstrip(), 2)] = int(data[0])


# Serialize data into file:
json.dump( delaydata, open( "TDC_data.json", 'w' ) )

