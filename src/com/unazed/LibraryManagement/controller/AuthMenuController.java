package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.View;

import javafx.fxml.FXML;
import javafx.scene.control.MenuItem;

public class AuthMenuController
{
  @FXML private MenuItem miViewRegister;
  @FXML private MenuItem miViewLogin;
  @FXML private MenuItem miPreferencesConfigDb;
  @FXML private MenuItem miHelpAbout;

  public static final View VIEW = View.AUTH_MENU;

  @FXML
  private void onViewLogin()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(LoginController.VIEW));
  }

  @FXML
  private void onViewRegister()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(RegisterController.VIEW));
  }

  @FXML
  private void onPreferencesConfigDb()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(ConfigDbController.VIEW));
  }

  @FXML
  private void onHelpAbout()
  {
    EventBus.get().publish(new Events.ViewSwitchEvent(AboutController.VIEW));
  }
}