#!/bin/bash
set -eu

function help () {
	echo -e "\nUsage: $0 [Mac Civ V application] [Windows Civ V directory] [Language code] [Language name] \n"
	echo "Default and the only tested language is Polish (code: PL_PL)."
	echo "Language code specifies source text lanuage, language name specifies source sounds language."
}

if [ $# -ne 2 -a $# -ne 4 ]
then
	help
	exit 1
fi

[ "$(uname -s)" == "Darwin" ] && MAC_DIR="$1/Contents/Assets" || MAC_DIR="$1"
WIN_DIR="$2"
PATCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LANGUAGE_CODE=${3:-PL_PL}
LANGUAGE_NAME=${4:-Polish}

if [ ! -d "$MAC_DIR/Assets/UI/Fonts/Tw Cent MT" ]
then
	echo "The target application is not Civ 5."
	exit 1
fi

if [ ! -d "$WIN_DIR/Assets/UI/Fonts/Tw Cent MT" ]
then
	echo "The source directory is not Civ 5."
	exit 1
fi

# Unpack extended font
echo "Unpacking extended font."
unzip -q -o -d "$MAC_DIR/Assets/UI/Fonts/Tw Cent MT" "$PATCH_DIR/font.zip"

# Set Polish plural rule
[ "$LANGUAGE_CODE" == "PL_PL" ] && sed -i '' "s/PluralRule>2</PluralRule>10</" "$MAC_DIR/Assets/Gameplay/XML/NewText/English.xml"

# Copy localisation files.
# In English these are sometimes en_US, sometimes EN_US,
# but in other languages these are always capitalised.
echo "Copying text files."
for code in 'en_US' 'EN_US'
do
	find "$MAC_DIR" -name "$code" -print0 | while read -d $'\0' directory
	do
		# English localisation in Windows ver.
		win_en="$WIN_DIR${directory#$MAC_DIR}"
		# Polish localisation in Windows ver.
		win_pl="${win_en%$code}$LANGUAGE_CODE"

		cp -r "$win_pl"/* "$directory"/
		# Masquarade as English
		find "$directory" -type f -name '*.xml' -print0 | while read -d $'\0' file
		do
			sed -i '' "s/$LANGUAGE_CODE/EN_US/g" "$file"
		done
	done
done

# Copy sounds
echo "Copying sounds."
find "$MAC_DIR" -type d -name "Speech" -print0 | while read -d $'\0' directory
do
	win="$WIN_DIR${directory#$MAC_DIR}"
	cp -r "$win/$LANGUAGE_NAME"/* "$directory/English/"
done

echo "Done! Dobrej gry!"

