import 'package:InstiApp/src/api/model/body.dart';
import 'package:InstiApp/src/api/model/event.dart';
import 'package:InstiApp/src/bloc_provider.dart';
import 'package:InstiApp/src/blocs/ia_bloc.dart';
import 'package:InstiApp/src/drawer.dart';
import 'package:InstiApp/src/utils/common_widgets.dart';
import 'package:InstiApp/src/utils/share_url_maker.dart';
import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

class EventPage extends StatefulWidget {
  final Future<Event> _eventFuture;

  EventPage(this._eventFuture);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Event event;

  int loadingUes = 0;

  bool _bottomSheetActive = false;

  @override
  void initState() {
    super.initState();
    event = null;
    widget._eventFuture.then((ev) {
      setState(() {
        event = ev;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var bloc = BlocProvider.of(context).bloc;
    var footerButtons = <Widget>[];
    if (event != null) {
      footerButtons.addAll([
        buildUserStatusButton("Going", 2, theme, bloc),
        buildUserStatusButton("Interested", 1, theme, bloc),
      ]);

      if ((event.eventWebsiteURL ?? "") != "") {
        footerButtons.add(IconButton(
          tooltip: "Open website",
          icon: Icon(OMIcons.language),
          onPressed: () async {
            if (await canLaunch(event.eventWebsiteURL)) {
              await launch(event.eventWebsiteURL);
            }
          },
        ));
      }
      if (event.eventVenues.isNotEmpty &&
          event.eventVenues[0].venueLatitude != null) {
        footerButtons.add(IconButton(
          tooltip: "Navigate to event",
          icon: Icon(OMIcons.navigation),
          onPressed: () async {
            String uri =
                "google.navigation:q=${event.eventVenues[0].venueLatitude},${event.eventVenues[0].venueLongitude}";
            if (await canLaunch(uri)) {
              await launch(uri);
            }
          },
        ));
      }
    }
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(
                OMIcons.menu,
                semanticLabel: "Show bottom sheet",
              ),
              onPressed: _bottomSheetActive
                  ? null
                  : () {
                      setState(() {
                        //disable button
                        _bottomSheetActive = true;
                      });
                      _scaffoldKey.currentState
                          .showBottomSheet((context) {
                            return BottomDrawer();
                          })
                          .closed
                          .whenComplete(() {
                            setState(() {
                              _bottomSheetActive = false;
                            });
                          });
                    },
            ),
          ],
        ),
      ),
      // bottomSheet: ,
      body: Container(
        foregroundDecoration: _bottomSheetActive
            ? BoxDecoration(
                color: Color.fromRGBO(100, 100, 100, 12),
              )
            : null,
        child: event == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          event.eventName,
                          style: theme.textTheme.display2.copyWith(
                              color: Colors.black, fontFamily: "Bitter"),
                        ),
                        SizedBox(height: 8.0),
                        Text(event.getSubTitle(), style: theme.textTheme.title),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PhotoViewableImage(
                        NetworkImage(event?.eventImageURL ??
                            event?.eventBodies[0].bodyImageURL),
                        "${event.eventID}",
                        fit: BoxFit.fitWidth),
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28.0, vertical: 16.0),
                    child: Text(
                      event?.eventDescription,
                      style: theme.textTheme.subhead,
                    ),
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  Divider(),
                ]
                  ..addAll(event.eventBodies
                      .map((b) => _buildBodyTile(b, theme.textTheme)))
                  ..addAll([
                    Divider(),
                    SizedBox(
                      height: 64.0,
                    )
                  ]),
              ),
      ),

      floatingActionButton: _bottomSheetActive || event == null
          ? null
          : FloatingActionButton(
              child: Icon(OMIcons.share),
              tooltip: "Share this event",
              onPressed: () async {
                await Share.share(
                    "Check this event: ${ShareURLMaker.getEventURL(event)}");
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: footerButtons,
    );
  }

  Widget _buildBodyTile(Body body, TextTheme theme) {
    return ListTile(
      title: Text(body.bodyName, style: theme.title),
      subtitle: Text(body.bodyShortDescription, style: theme.subtitle),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(body.bodyImageURL),
      ),
      onTap: () {
        Navigator.of(context).pushNamed("/body/${body.bodyID}");
      },
    );
  }

  RaisedButton buildUserStatusButton(
      String name, int id, ThemeData theme, InstiAppBloc bloc) {
    return RaisedButton(
      color: event?.eventUserUes == id ? theme.accentColor : Colors.white,
      textColor: event?.eventUserUes == id ? Colors.white : null,
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.accentColor,
          ),
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: Row(children: () {
        var rowChildren = <Widget>[
          Text(name),
          SizedBox(
            width: 8.0,
          ),
          Text(
              "${id == 1 ? event?.eventInterestedCount : event?.eventGoingCount}"),
        ];
        if (loadingUes == id) {
          rowChildren.insertAll(0, [
            SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(
                      event?.eventUserUes == id
                          ? Colors.white
                          : theme.accentColor),
                  strokeWidth: 2,
                )),
            SizedBox(
              width: 8.0,
            )
          ]);
        }
        return rowChildren;
      }()),
      onPressed: () async {
        setState(() {
          loadingUes = id;
        });
        await bloc.updateUesEvent(event, event.eventUserUes == id ? 0 : id);
        setState(() {
          loadingUes = 0;
          // event has changes
        });
      },
    );
  }
}
