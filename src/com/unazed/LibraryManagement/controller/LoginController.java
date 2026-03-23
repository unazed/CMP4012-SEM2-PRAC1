package com.unazed.LibraryManagement.controller;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

public class LoginController
{
  @FXML private TextField tfLoginEmail;
  @FXML private PasswordField tfLoginPassword;
  @FXML private Button btnLogin;

  @FXML
  public void initialize()
  {
  }

  @FXML
  private void onLoginClick()
  {
    String email = tfLoginEmail.getText();
    String password = tfLoginPassword.getText();

    if (email.isEmpty() || password.isEmpty())
    {
      return;
    }

    System.out.println("Login attempted with email: " + email);
  }
}