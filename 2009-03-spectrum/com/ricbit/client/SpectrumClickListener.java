package com.ricbit.client;

import com.google.gwt.user.client.ui.ClickListener;
import com.google.gwt.user.client.ui.Widget;

public class SpectrumClickListener implements ClickListener {

  private final SpectrumLogic logic;

  public SpectrumClickListener(SpectrumLogic logic) {
    this.logic = logic;
  }

  public void onClick(Widget sender) {
    logic.clear();
  }

}
