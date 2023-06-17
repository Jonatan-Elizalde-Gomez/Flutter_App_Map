import 'package:flutter/material.dart';
import 'package:georeferenciados_examen_final/MapScreen.dart';
import 'package:google_maps_webservice/places.dart';

class PlaceScreen extends StatefulWidget {
  PlaceScreen({Key? key}) : super(key: key);

  @override
  _PlaceScreenState createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  final GoogleMapsPlaces _places =
      GoogleMapsPlaces(apiKey: 'AIzaSyD-pqNULR3iJPOr_Ejphv3jRCpv22jwHH0');
  final TextEditingController _searchController = TextEditingController();

  List<Prediction> _searchResults = [];
  PlaceDetails? selectedPlaceDetails;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchText() async {
    setState(() {
      _searchController.clear();
    });

    if ("".isNotEmpty) {
      PlacesAutocompleteResponse response = await _places.autocomplete(
        "value",
        language: 'es',
      );

      setState(() {
        _searchResults = response.predictions;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _onSearchChanged(String value) async {
    if (value.isNotEmpty) {
      PlacesAutocompleteResponse response = await _places.autocomplete(
        value,
        language: 'es',
      );

      setState(() {
        _searchResults = response.predictions;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _onPlaceSelected(String placeId) async {
    PlacesDetailsResponse response = await _places.getDetailsByPlaceId(placeId);
    if (response.status == "OK") {
      PlaceDetails result = response.result;
      setState(() {
        _searchController.text = result.name;
        selectedPlaceDetails = result;
        _searchResults =
            []; // Limpiar los resultados de búsqueda al seleccionar una opción
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 50, 16.0, 16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Nombre del lugar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                      bottomLeft: _searchResults.isNotEmpty
                          ? Radius.zero
                          : Radius.circular(10.0),
                      bottomRight: _searchResults.isNotEmpty
                          ? Radius.zero
                          : Radius.circular(10.0),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _clearSearchText,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            SizedBox(height: 0), // Espacio vertical de 32 puntos

            if (_searchResults.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    bottomRight: Radius.circular(10.0),
                  ),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  maxHeight: 300.0,
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    Prediction result = _searchResults[index];
                    return ListTile(
                      title: Text(result.structuredFormatting!.mainText),
                      onTap: () => _onPlaceSelected(result.placeId!),
                    );
                  },
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        data: selectedPlaceDetails,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // Fondo azul
                  onPrimary: Colors.white, // Letra blanca
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Bordes redondeados (ajusta el valor según tus necesidades)
                  ),
                ),
                child: Text('Mandar locación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
