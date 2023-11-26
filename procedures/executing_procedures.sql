SET SERVEROUTPUT ON 


BEGIN
    add_trucks('Volvo FH16', 500, 'ASFAS', '324323423324');
    add_trucks('Mercedes-Benz Actros', 200, 'BKAS8e424', '342332423324');
    add_trucks('Ford F-150', 200, 'FAFSAF', '00001000000300');
    add_trucks('Volvo FH16', 70, 'DDDFAS', '32432342132324');
    add_trucks('Mercedes-Benz Actros', 500, 'B11K81L424', '8881888188888');
    add_trucks('Ford F-150', 200, 'FAP1SA1F', '2341234324234234');
    add_trucks('Volvo FH16', 700, 'ASF1A1S', '3243234211324');
    add_trucks('Mercedes-Benz Actros', 100, 'BK1AS8e4124', '134112332423324');
    add_trucks('Ford F-150', 200, 'FAF11SA1F', '0001000100010300');
    add_trucks('Volvo FH16', 100, 'DDDFA11S', '324323412321324');
    add_trucks('Mercedes-Benz Actros', 500, 'BK81L424', '8818818888888');
    add_trucks('Ford F-150', 200, 'FAP1SA1F', '23423413242342134');

    commit;
END;
/

begin
    add_trucks('Ford F-150', 1000, 'FAP1SA1F', '2341234324234234');
    commit;
end;

--DELETE FROM customers;
--DELETE FROM truck_details;
DELETE FROM trucks;
BEGIN
    REGISTER_CUSTOMER('Anna Nowak', '1234901234', '2B', 'Krakowska', '30-001', 'Kraków', 'Ma?opolskie', 'Polska', 'anna@example.com', '+48123456789');
    REGISTER_CUSTOMER('Piotr Kowalski', '0981321123', '3C', 'Gda?ska', '80-001', 'Gda?sk', 'Pomorskie', 'Polska', 'piotr@example.com', '+48123456788');
    REGISTER_CUSTOMER('Barbara Wi?niewska', '1123344555', '4D', 'Warszawska', '10-002', 'Olsztyn', 'Warmi?sko-Mazurskie', 'Polska', 'barbara@example.com', '+48123456787');
    REGISTER_CUSTOMER('Jan Kowalczyk', '2222444111', '5E', 'Pozna?ska', '60-003', 'Pozna?', 'Wielkopolskie', 'Polska', 'jan@example.com', '+48123456786');
    REGISTER_CUSTOMER('Ewa Lewandowska', '3345559999', '6F', 'Wroc?awska', '50-004', 'Wroc?aw', 'Dolno?l?skie', 'Polska', 'ewa@example.com', '+48123456785');
    REGISTER_CUSTOMER('Tomasz Wójcik', '4444666777', '7G', 'Lubelska', '20-005', 'Lublin', 'Lubelskie', 'Polska', 'tomasz@example.com', '+48123456784');
    REGISTER_CUSTOMER('Ma?gorzata Kaczmarek', '5556777333', '8H', 'Sosnowiecka', '40-006', 'Katowice', '?l?skie', 'Polska', 'malgorzata@example.com', '+48123456783');
    REGISTER_CUSTOMER('Krzysztof Zielinski', '6667888666', '9I', 'Gdynia', '70-007', 'Gdynia', 'Pomorskie', 'Polska', 'krzysztof@example.com', '+48123456782');
    REGISTER_CUSTOMER('Agnieszka Szymanska', '7778899944', '10J', '?ódzka', '90-008', '?ód?', '?ódzkie', 'Polska', 'agnieszka@example.com', '+48123456781');
    REGISTER_CUSTOMER('Marek Pawlowski', '8888002222', '11K', 'Rzeszowska', '35-009', 'Rzeszów', 'Podkarpackie', 'Polska', 'marek@example.com', '+48123456780');


    commit;
END;
/

select * from customers


/*
delete from waybills;
delete from cargo;
delete from route_segments;
delete from routes;
delete from orders;

*/
BEGIN

    register_cargo(1, 'Newelska 6, Warszawa', 'Przyk?adowy ?adunek o wadze 100 kg', 100, 'instrukcje dotycz?ce przewozu');
    register_cargo(1, 'Newelska 6, Warszawa', 'Przyk?adowy ?adunek o wadze 100 kg', 100, 'instrukcje dotycz?ce przewozu');
    register_cargo(2, 'Chmielna 7, Warszawa', 'Przyk?adowy ?adunek o wadze 50 kg', 150, 'instrukcje dotycz?ce przewozu');
    register_cargo(3, 'Stalowa 10, Warszawa', 'Przyk?adowy ?adunek o wadze 50 kg', 150, 'instrukcje dotycz?ce przewozu');


    COMMIT;
END;
/

BEGIN
    submit_an_order(1, 10);
    submit_an_order(2, 13);
    submit_an_order(3, 7);
    COMMIT;
END;
/



BEGIN
    confirm_route(1);
    COMMIT;
END;
/

BEGIN
    complete_route(1);
    COMMIT;
END;
/

BEGIN
    cancel_order(4);
END;

CREATE OR REPLACE PROCEDURE insert_data IS
    v_repit NUMBER;
    cargo_w NUMBER;
    v_route NUMBER;
    v_cust NUMBER;
BEGIN 
    cargo_w := 20;
    v_repit := 0;
    cargo_w := 20;
    v_cust := 0;
        WHILE v_repit < 10 LOOP
            
            
            v_cust := v_cust + 1;
    
            register_cargo(v_cust, 'Newelska 6, warszawa', 'Przyk?adowy ?adunek o wadze ' || cargo_w ||' kg', cargo_w, 'instrukcje dotycz?ce przewozu');
            cargo_w := cargo_w + 10;
            --select max(r.route_id) into v_route
            --from routes r join truck_details t
            --on r.truck_details_id = t.truck_details_id
            --where t.AVAILEBLE_CAPACITY < 10;
            --complete_route(v_route);
            v_repit := v_repit + 1;
            --submit_an_order(v_cust, 25);
        END LOOP;
    
END insert_data;
/

begin
    insert_data();
end;

select * from cargo

select * from cargo where status = 'Przydzielony' and order_id = 319

        SELECT w.destination_point
        FROM waybills w
        JOIN cargo c ON c.cargo_id = w.cargo_id
        WHERE c.order_id = 314
        AND c.status = 'Przyjete'
        AND ROWNUM = 1;
