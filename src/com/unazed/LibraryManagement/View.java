package com.unazed.LibraryManagement;

import java.net.URL;
import java.util.logging.Level;
import java.util.logging.Logger;

public enum View
{
  LOGIN("Login"), AUTH_MENU("AuthMenu"),
  MAIN("Main"),
  REGISTER("Register"),
  CONFIG_DB("ConfigDb"),
  ABOUT("About"),
  DASHBOARD("Dashboard"), APP_MENU("AppMenu");

  private static final Logger logger = Logger.getLogger(View.class.getName());
  private final String viewName;

  static
  {
    for (View view : values())
    {
      URL url = View.class.getResource(view.getFxmlPath());
      if (url == null)
        logger.log(
          Level.WARNING, "Missing FXML for view: " + view.getFxmlPath());
    }
  }

  View(String viewName)
  {
    this.viewName = viewName;
  }

  public String getFxmlPath()
  {
    return "/views/" + viewName + ".fxml";
  }

  public String getViewName()
  {
    return viewName;
  }
}
