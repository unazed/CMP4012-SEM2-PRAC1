package com.unazed.LibraryManagement.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializer;
import com.unazed.LibraryManagement.model.gen.UserRole;
import com.unazed.LibraryManagement.model.gen.UserStatus;

public class GsonProvider
{
  public static Gson get()
  {
    return new GsonBuilder()
      .registerTypeAdapter(LocalDateTime.class,
        (JsonDeserializer<LocalDateTime>) (json, type, ctx)
        -> LocalDateTime.parse(json.getAsString()))
      .registerTypeAdapter(LocalDate.class,
        (JsonDeserializer<LocalDate>) (json, type, ctx)
        -> LocalDate.parse(json.getAsString()))
      .registerTypeAdapter(OffsetDateTime.class,
        (JsonDeserializer<OffsetDateTime>) (json, type, ctx)
        -> OffsetDateTime.parse(json.getAsString()))
      .registerTypeAdapter(UserRole.class,
        (JsonDeserializer<UserRole>) (json, type, ctx)
        -> UserRole.fromValue(json.getAsString()))
      .registerTypeAdapter(UserStatus.class,
        (JsonDeserializer<UserStatus>) (json, type, ctx)
        -> UserStatus.fromValue(json.getAsString()))
      .create();
  }
}
