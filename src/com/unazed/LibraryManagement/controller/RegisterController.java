package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.View;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

public class RegisterController
{
  @FXML private TextField tfRegisterEmail;
  @FXML private TextField tfRegisterUsername;
  @FXML private PasswordField tfRegisterPassword;
  @FXML private PasswordField tfRegisterConfirmPassword;
  @FXML private Button btnRegister;

  public static final View VIEW = View.REGISTER;

  @FXML
  public void initialize()
  {
  }

  @FXML
  private void onRegisterClick()
  {
    String email = tfRegisterEmail.getText();
    String username = tfRegisterUsername.getText();
    String password = tfRegisterPassword.getText();
    String confirmPassword = tfRegisterConfirmPassword.getText();

    if (email.isEmpty() || username.isEmpty() 
        || password.isEmpty() || confirmPassword.isEmpty())
    {
      return;
    }

    if (!password.equals(confirmPassword))
      {
        return;
    }

  }
}