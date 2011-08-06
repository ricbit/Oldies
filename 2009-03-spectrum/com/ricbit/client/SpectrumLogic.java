package com.ricbit.client;

public class SpectrumLogic {

  private static final double GAMMA = 3.0;
  private final SpectrumView view;
  private final double normalization;

  private boolean isMouseDown;
  private int lastX;
  private int lastY;
  private double[] lightSpectrum;

  public SpectrumLogic(SpectrumView view) {
    this.view = view;
    isMouseDown = false;
    lightSpectrum = new double[440];
    normalization = SpectrumConstants.CANVAS_HEIGHT;      
  }

  public void clear() {
    view.clear();
    for (int i = 0; i < lightSpectrum.length; i++) {
      lightSpectrum[i] = 0.0;
    }
    evalColor();
  }

  private void evalColor() {
    double red = integrate(SpectrumConstants.redCone);
    double green = integrate(SpectrumConstants.greenCone);
    double blue = integrate(SpectrumConstants.blueCone);
    view.setColor(encodeColorTriplet(red, green, blue));
  }

  private String encodeColorTriplet(double red, double green, double blue) {
    return "#" + encodeColor(red) + encodeColor(green) + encodeColor(blue);
  }

  private String encodeColor(double color) {
    int scaledColor = (int) Math.floor(255.0 * color);
    String rawColor = "00" + Integer.toHexString(Math.min(scaledColor, 255));
    return rawColor.substring(rawColor.length() - 2);
  }

  private double integrate(double[] coneResponse) {
    double sum = 0.0;
    for (int i = 0; i < coneResponse.length; i++) {
      sum += Math.pow(coneResponse[i] * lightSpectrum[i] / normalization, GAMMA);
    }
    return Math.min(sum, 1.0);
  }

  public void mouseDown(int x, int y) {
    isMouseDown = true;
    lastX = x;
    lastY = y;
    view.drawLine(x, y);
    lightSpectrum[x] = SpectrumConstants.CANVAS_HEIGHT - y;
    evalColor();
  }

  public void mouseUp() {
    isMouseDown = false;
  }

  public void mouseMove(int x, int y) {
    if (isMouseDown && x != lastX) {
      view.drawRegion(lastX, lastY, x, y);
      if (lastX < x)
        fillLight(lastX, lastY, x, y);
      else
        fillLight(x, y, lastX, lastY);
      evalColor();
      lastX = x;
      lastY = y;
    }
  }

  private void fillLight(int startX, int startY, int endX, int endY) {
    double rate = (double)(endY - startY) / (double)(endX - startX);
    for (int i = startX; i <= endX; i++) {
      lightSpectrum[i] = 
        SpectrumConstants.CANVAS_HEIGHT - ((double)(startY) + rate * (double)(i - startX));
    }
  }

  public void mouseLeave() {
    isMouseDown = false;
  }

}
