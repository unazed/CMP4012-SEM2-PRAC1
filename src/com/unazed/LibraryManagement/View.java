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
  DASHBOARD("Dashboard"), APP_MENU("AppMenu"),
  DASHBOARD_ADD_MODIFY_BOOKS("dashboard/AddModifyBooks"),
  DASHBOARD_VIEW_BOOKS("dashboard/ViewBooks"),
  DASHBOARD_VIEW_BOOK_DETAIL("dashboard/ViewBookDetail"),
  DASHBOARD_VIEW_MY_LOANS("dashboard/ViewMyLoans"),
  DASHBOARD_VIEW_MEMBERS("dashboard/ViewMembers"),
  DASHBOARD_VIEW_MEMBERS_DETAIL("dashboard/ViewMembersDetail"),
  DASHBOARD_VIEW_ALL_LOANS("dashboard/ViewAllLoans");

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
