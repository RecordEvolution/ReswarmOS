systemctl stop reagent.service
systemctl stop reagent-manager.service

systemctl disable reagent.service
systemctl disable reagent-manager.service

rm /opt/reagent/reswarmify/services/reagent.service
rm /opt/reagent/reswarmify/services/reagent-manager.service