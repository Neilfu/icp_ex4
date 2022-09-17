import Iter "mo:base/Iter";
import List "mo:base/List";
import Time "mo:base/Time";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
actor {
  public type Message = {
    text: Text;
    time: Time.Time;
  };

  public type Microblog = actor{
    follow: shared(Principal) -> async ();
    follows: shared query () -> async [Principal];
    post: shared (Text) -> async ();
    posts: shared query (since:Time.Time) -> async [Message];
    timeline: shared (since:Time.Time) -> async [Message];
  };

  var followed: List.List<Principal> = List.nil();

  public shared func follow(id: Principal):async() {
    followed := List.push(id, followed);
  };

  public shared query func follows(): async [Principal]{
    List.toArray(followed);
  };

  stable var messages: List.List<Message> = List.nil();

  public shared query (msg) func getId(): async Text{
    Principal.toText(msg.caller);
  };

  public shared (msg) func post(text:Text): async() {
    Debug.print(Principal.toText(msg.caller));
    assert(Principal.toText(msg.caller) == "2vxsx-fae");
    messages := List.push({text=text;time=Time.now()}, messages);

  };

  public shared query func posts(since: Time.Time): async [Message] {
    var filter_result:List.List<Message> = List.nil();
    for (msg in Iter.fromList(messages)){
      if (msg.time >= since){
        filter_result := List.push(msg, filter_result);
      }
    };
    List.toArray(filter_result);
  };

  public shared func timeline(since:Time.Time): async [Message]{
    var all: List.List<Message> = List.nil();
    for (id in Iter.fromList(followed)){
      let canister: Microblog = actor(Principal.toText(id));
      let msgs = await canister.posts(since);

      for (msg in Iter.fromArray(msgs)){
          if (msg.time >= since){
            all := List.push(msg, all);
          };
      }
    };

    List.toArray(all);
  }

};
