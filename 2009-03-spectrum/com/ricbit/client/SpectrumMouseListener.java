package com.ricbit.client;

import com.google.gwt.user.client.ui.MouseListener;
import com.google.gwt.user.client.ui.Widget;

public class SpectrumMouseListener implements MouseListener {

  private final SpectrumLogic logic;

  public SpectrumMouseListener(SpectrumLogic logic) {
    this.logic = logic;
  }

  public void onMouseDown(Widget sender, int x, int y) {
    logic.mouseDown(x, y);
  }

  public void onMouseEnter(Widget sender) {
    // TODO Auto-generated method stub
  }

  public void onMouseLeave(Widget sender) {
    logic.mouseLeave();
  }

  public void onMouseMove(Widget sender, int x, int y) {
    logic.mouseMove(x, y);
  }

  public void onMouseUp(Widget sender, int x, int y) {
    logic.mouseUp();
  }

}
