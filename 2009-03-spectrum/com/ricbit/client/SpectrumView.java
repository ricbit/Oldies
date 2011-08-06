package com.ricbit.client;

import com.google.gwt.user.client.DOM;
import com.google.gwt.user.client.ui.HTML;

import gwt.canvas.client.Canvas;

public class SpectrumView {

  private static final String KINDA_YELLOW = "#e0e0b0";
  private final Canvas canvas;
  private final HTML colorPanel;

  public SpectrumView(Canvas canvas, HTML colorPanel) {
    this.canvas = canvas;
    this.colorPanel = colorPanel;
  }

  public void clear() {
    canvas.setBackgroundColor(KINDA_YELLOW);
    canvas.clear();
  }

  public void drawLine(int x, int y) {
    canvas.clearRect(x, 0, 1, SpectrumConstants.CANVAS_HEIGHT);
    canvas.beginPath();
    canvas.moveTo(x, SpectrumConstants.CANVAS_HEIGHT);
    canvas.lineTo(x, y);
    canvas.stroke();
  }

  public void drawRegion(int lastX, int lastY, int x, int y) {
    canvas.clearRect(Math.min(lastX, x), 0, Math.abs(lastX - x), SpectrumConstants.CANVAS_HEIGHT);
    canvas.beginPath();
    canvas.moveTo(lastX, SpectrumConstants.CANVAS_HEIGHT);
    canvas.lineTo(lastX, lastY);
    canvas.lineTo(x, y);
    canvas.lineTo(x, SpectrumConstants.CANVAS_HEIGHT);
    canvas.fill();
  }

  public void setColor(String color) {
    DOM.setStyleAttribute(colorPanel.getElement(), "backgroundColor", color);
  }

}
