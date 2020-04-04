cur_dir=$(pwd)

echo -e "\nChecking out packages/apps/Bluetooth to quartz-dev\n"
cd packages/apps/Bluetooth
git fetch -q aospa &> /dev/null
git checkout -q aospa/quartz-dev &> /dev/null

cd $cur_dir
