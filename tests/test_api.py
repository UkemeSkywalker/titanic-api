def test_get_people(client):
    response = client.get('/people')
    assert response.status_code == 200

def test_post_person(client):
    data = {
        "survived": 1,
        "passengerClass": 1,
        "name": "Test Person",
        "sex": "male",
        "age": 30.0,
        "siblingsOrSpousesAboard": 0,
        "parentsOrChildrenAboard": 0,
        "fare": 50.0
    }
    response = client.post('/people', json=data)
    assert response.status_code in [200, 201]
