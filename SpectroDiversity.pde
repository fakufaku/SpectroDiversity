  /**
 * Copyright (c) 2014 Robin Scheibler
 *  
 * This code displays a real time spectrogram of the audio in line signal.
 * 
 * This code is public domain.
 */

import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;

Minim minim;
AudioInput in;
FFT fft;
String windowName;

int FFTSize = 1024;
int Length = 1400;
int index = 0;

float[] overlap = new float[FFTSize/2];
float[] buffer = new float[FFTSize];
float[] spectrum = new float[FFTSize/2+1];

int maxColor = 25;
int logAddF = 10;
int logMulF = 1;

void setup()
{
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.MONO, FFTSize/2);
  
  // create an FFT object that has a time-domain buffer the same size as jingle's sample buffer
  // note that this needs to be a power of two and that it means the size of the spectrum
  // will be 512. see the online tutorial for more info.
  fft = new FFT(FFTSize, in.sampleRate());

  // create image of good size
  size(Length, fft.specSize());

  // initialize overlap to zero
  for (int i = 0 ; i < FFTSize/2 ; i++)
    overlap[i] = 0.;
    
  // setup color mode
  colorMode(RGB, maxColor);
  
  textFont(createFont("SanSerif", 12));
  windowName = "None";
  
  loadPixels();
}

void draw()
{
  background(0);
  stroke(255);
  
  // fill buffer
  for (int i = 0 ; i < FFTSize/2 ; i++)
  {
    buffer[i] = overlap[i];
    buffer[i+FFTSize/2] = in.mix.get(i);
  }
  
  // perform a forward FFT on the buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.right or jingle.left
  fft.forward(buffer);
  
  
  for (int i = 0 ; i < fft.specSize() ; i++)
    spectrum[i] = logMulF*log(fft.getBand(fft.specSize()-1-i)) + logAddF;

  /*
  float max = spectrum[0];
  float min = max;
  for (int i = 1 ; i < fft.specSize() ; i++)
  {
    if (spectrum[i] < min)
      min = spectrum[i];
    if (spectrum[i] > max)
      max = spectrum[i];
  }
  println("Min=", min, " Max=", max);
  */

  // move the current input buffer to overlap
  for (int i = 0 ; i < FFTSize/2 ; i++)
    overlap[i] = in.mix.get(i);

  // write new spectrum display
  if (index < Length)
  {
    for (int i = 0 ; i < fft.specSize() ; i++)
      pixels[i*Length + index] = color(spectrum[i], spectrum[i], spectrum[i]);
    index += 1;
  }
  else
  {
    // first move all the columns by one to the left
    for (int i = 0 ; i < Length-1 ; i++)
      for (int j = 0 ; j < fft.specSize() ; j++)
        pixels[j*Length + i] = pixels[j*Length + i+1];

    // copy the new spectrum in the last row
    for (int i = 0 ; i < fft.specSize() ; i++)
      pixels[i*Length + Length - 1] = color(spectrum[i], spectrum[i], spectrum[i]);
  }
  
  updatePixels();
  
  // keep us informed about the window being used
  text("The window being used is: " + windowName, 5, 20);
}

void keyReleased()
{
  if ( key == 'w' ) 
  {
    // a Hamming window can be used to shape the sample buffer that is passed to the FFT
    // this can reduce the amount of noise in the spectrum
    fft.window(FFT.HAMMING);
    windowName = "Hamming";
  }
  
  if ( key == 'e' ) 
  {
    fft.window(FFT.NONE);
    windowName = "None";
  }
}

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  
  super.stop();
}

