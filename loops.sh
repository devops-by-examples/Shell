for mission in $(cat mission-name.txt)
do
    create-and-launch-rocket $mission
done



for mission in 1 2 3 4 5 6
do 
    create-and-launch-rocket mission-$mission
done



for mission in {0..100}
do
    create-and-launch-rocket mission-$mission
done


for (( mission = 0 ; mission <=100 ; mission++ ))
do 
    create-and-launch-rocket mission-$mission
done
