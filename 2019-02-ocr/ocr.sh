# Usage: ./ocr.sh document.ps

gs -dTextAlphaBits=4 -r200 -sDEVICE=pnggray -sOutputFile=$1.%04d.png -dNOPAUSE $1 -c quit
echo > $1.txt
for f in `ls $1.*.png`; do
  echo "Processing page $f"
  tesseract $f stdout >> $1.txt
done
rm $1.*.png
