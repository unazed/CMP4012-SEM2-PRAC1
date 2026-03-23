package com.unazed.LibraryManagement.controller;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class StatusMenuController
{
  @FXML private Label labelStatus;

  public void setStatus(String message)
  {
    labelStatus.setText(message);
  }
}
