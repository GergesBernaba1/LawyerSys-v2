using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace LawyerSys.Realtime;

[Authorize(Policy = "CustomerAccess")]
public class NotificationHub : Hub
{
}
