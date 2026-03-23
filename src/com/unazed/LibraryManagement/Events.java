package com.unazed.LibraryManagement;

import com.unazed.LibraryManagement.model.User;

public class Events
{
  public static class ViewSwitchEvent
  {
    private final String view;

    public ViewSwitchEvent(String view)
    {
      this.view = view;
    }

    public String getView()
    {
      return view;
    }
  }

  public static class UserAuthenticatedEvent
  {
    private final User user;

    public UserAuthenticatedEvent(User user)
    {
      this.user = user;
    }

    public User getUser()
    {
      return user;
    }
  }
}