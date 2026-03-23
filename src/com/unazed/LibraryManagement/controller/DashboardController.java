package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;
import com.unazed.LibraryManagement.model.User.UserAware;

import javafx.fxml.FXML;

public class DashboardController implements UserAware
{
  public static final View VIEW = View.DASHBOARD;
  private User user;

  @FXML
  public void initialize()
  {
  }

  @Override
  public void setUser(User user)
  {
    this.user = user;
  }
}
