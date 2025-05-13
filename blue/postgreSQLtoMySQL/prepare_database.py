#!/usr/bin/env python3
import re
import sys

def add_auto_increment(content):

    # 1. ADD AUTO_INCREMENT TO COLUMN "id" (int(...) o bigint) NOT NULL
    content = re.sub(r"(\bid\b\s+(?:int\(\d+\)|bigint)\s+NOT NULL)(?!\s+AUTO_INCREMENT)",
                     r"\1 AUTO_INCREMENT", content, flags=re.IGNORECASE)

    # 2. SECURES THAT THE COLUMN "id" ALSO HAS PRIMARY KEY INLINE.
    #    (ONLY ADDS IF IT DOESN'T HAVE "PRIMARY KEY" IN THE SAME LINE)
    content = re.sub(r"(\bid\b\s+(?:int\(\d+\)|bigint)\s+NOT NULL AUTO_INCREMENT)(?!\s+PRIMARY KEY)",
                     r"\1 PRIMARY KEY", content, flags=re.IGNORECASE)
    return content

def fix_default_timestamp(content):

    # REPLACE "timestamp DEFAULT 0 NOT NULL" WITH "timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP"
    content = re.sub(r"timestamp\s+DEFAULT\s+0\s+NOT NULL",
                     "timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP",
                     content, flags=re.IGNORECASE)

    # REPLACE "timestamp DEFAULT 0" WITH "timestamp DEFAULT CURRENT_TIMESTAMP"
    content = re.sub(r"timestamp\s+DEFAULT\s+0",
                     "timestamp DEFAULT CURRENT_TIMESTAMP",
                     content, flags=re.IGNORECASE)
    return content

def remove_alter_primary_keys(content):

    # REMOVE 'ALTER TABLE' ADD CONSTRAINT 'PRIMARY KEY'
    return re.sub(r"(?m)^ALTER TABLE\s+\S+\s+ADD CONSTRAINT\s+\S+\s+PRIMARY KEY\s+\([^)]*\);\s*$", "", content, flags=re.IGNORECASE)

def main(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as f:
        content = f.read()

    # APPLY TRANSFORMATIONS
    content = add_auto_increment(content)
    content = fix_default_timestamp(content)
    content = remove_alter_primary_keys(content)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Archivo procesado y guardado en {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python postprocess_sql.py <archivo_entrada> <archivo_salida>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])