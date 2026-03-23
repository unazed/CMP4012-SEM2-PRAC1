package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;

import javafx.fxml.FXML;
import javafx.scene.control.MenuItem;

public class AuthMenuController
{
  @FXML private MenuItem miViewRegister;
  @FXML private MenuItem miViewLogin;
  @FXML private MenuItem miPreferencesConfigDb;
  @FXML private MenuItem miHelpAbout;

  @FXML
  private void onViewLogin()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent("Login"));
  }

  @FXML
  private void onViewRegister()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent("Register"));
  }

  @FXML
  private void onPreferencesConfigDb()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent("ConfigDb"));
  }

  @FXML
  private void onHelpAbout()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent("About"));
  }
}