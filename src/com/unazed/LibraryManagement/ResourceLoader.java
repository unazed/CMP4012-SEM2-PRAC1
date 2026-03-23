package com.unazed.LibraryManagement;

import java.io.IOException;
import java.net.URL;
import java.util.logging.Level;
import java.util.logging.Logger;

import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;

public class ResourceLoader
{
  private static final Logger logger = Logger.getLogger(
    ResourceLoader.class.getName());

  public static URL getFxmlUrl(View view)
  {
    URL fxml = ResourceLoader.class.getResource(view.getFxmlPath());
    if (fxml == null)
    {
      logger.log(Level.SEVERE, "Failed to find view: " + view.getFxmlPath());
      throw new IllegalArgumentException(
        "View not found: " + view.getViewName());
    }
    return fxml;
  }

  public static Parent loadFxml(View view) throws IOException
  {
    URL fxmlUrl = getFxmlUrl(view);
    try
    {
      return FXMLLoader.load(fxmlUrl);
    } catch (IOException ioExc)
    {
      logger.log(Level.SEVERE, "Failed to load FXML for view: " + view, ioExc);
      throw ioExc;
    }
  }
}