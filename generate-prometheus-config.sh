#variables
TEMPLATE_FILE="./prometheus/prometheus.template.yml"
OUTPUT_FILE="./prometheus/prometheus.yml"
VM_LIST_FILE="./vm_list.txt"
if [ ! -f "$VM_LIST_FILE" ]; then
  echo "Error: $VM_LIST_FILE does not exist."
  exit 1
fi
TARGETS=$(awk '{print "\"" $1 ":9100\""}' $VM_LIST_FILE | paste -sd "," -)
sed "s|\${VM_LIST}|$TARGETS|" "$TEMPLATE_FILE" > "$OUTPUT_FILE"
echo " prometheus.yml successfully generated!"
echo "Contents:"
cat "$OUTPUT_FILE"
