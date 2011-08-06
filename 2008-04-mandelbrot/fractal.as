import flash.display.BitmapData;

var fractal:BitmapData=new BitmapData (256,256,false,0);
this.createEmptyMovieClip("movie", this.getNextHighestDepth());
movie.attachBitmap(fractal, movie.getNextHighestDepth(), "auto",true);
movie._x=0; movie._y=0;

for (var i:Number=0; i<256; i++)
  for (var j:Number=0; j<128; j++) {
    var color:Number=Mandelbrot((i/256)*2.5-2,j/100);
    fractal.setPixel(i,128+j,color);
    fractal.setPixel(i,128-j,color);
  }

stop();

function Mandelbrot(xc:Number, yc:Number):Number {
	var i:Number, x:Number, y:Number, x2:Number, y2:Number;

	x=0; y=0; x2=0; y2=0; i=0;
	while (i++<32) {
      if (x2+y2>4)
        return (Math.pow(i/32,0.7)*0xFF00)&0xFF00;
	  y=2*x*y+yc;
	  x=x2-y2+xc;
	  x2=x*x;
	  y2=y*y;
	}
	return 0xFFFFFF;
}
