/* Log authorization checks. */
// Log. Requires { security.polkit.debug = true; }
// polkit.addRule(function(action, subject) {
//   polkit.log("user " + JSON.stringify(subject) + " is attempting action " + JSON.stringify(action));
// });
polkit.addRule(function(action, subject) {
  if (subject.isInGroup("users")
    && action.id == "org.freedesktop.login1.power-off")
    return polkit.Result.YES;
  if (subject.isInGroup("users")
    && action.id == "org.freedesktop.login1.power-off-multiple-sessions")
    return polkit.Result.YES;
  if (subject.isInGroup("users")
    && action.unit == "poweroff.target"
    && action.verb == "start")
    return polkit.Result.YES;
});
