import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SeasonListWidget extends StatelessWidget {
  const SeasonListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 37, 37, 37),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 5),
              child: Text(
                'Staffeln',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                ),
              ),
            )),
        Expanded(
          child: ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                height: 50,
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? const Color.fromARGB(255, 30, 30, 30)
                      : const Color.fromARGB(255, 37, 37,
                          37), // Unterschiedliche Farben für jede zweite Zeile
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Season ${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Container(
                          child: Icon(Icons.fiber_manual_record,
                              size: 5,
                              color: const Color.fromARGB(255, 248, 144, 231)),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Container(
                          child: Text('20:30'),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                          child: Icon(Icons.fiber_manual_record,
                              size: 5,
                              color: const Color.fromARGB(255, 248, 144, 231)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        child: Icon(Icons.tv),
                      ),
                    ),                    
                    Spacer(),
                    Container(
                      width: 20,
                      child: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
