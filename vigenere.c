// implementation of vigenere cipher alogrithm. this code can encrypt and decrypt texts using a key.
// written by Antoine PASCAL, github username Axetriks, 14th of october, 2022

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <time.h>

#define MAX_SIZE 1000000
#define MAX_KEY_SIZE 1000000


//tableaux utilisés pour stocker l'alphabet en minuscule et majuscule pour l'algorithme
char Alphabet[26] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};
char alphabet[26] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};


//fonction qui va encoder le texte en utilisant l'algorithme de vigenère
void cipher(char cleartext[], char key[], char ciphertext[])
{
    int count = 0;
    int keycount = 0;

    if (cleartext[0] != '\0')
    {
        do
        {
            if (cleartext[count] <= 'z' && cleartext[count] >= 'a')
            {
                ciphertext[count] = alphabet[((cleartext[count] - 'a') + (key[keycount % strlen(key)] - 'a')) % 26];
                count++;
                keycount++;
            }
            else if (cleartext[count] <= 'Z' && cleartext[count] >= 'A')
            {
                ciphertext[count] = Alphabet[((cleartext[count] - 'A') + (key[keycount % strlen(key)] - 'a')) % 26];
                count++;
                keycount++;
            }
            else
            {
                ciphertext[count] = cleartext[count];
                count++;
            }
        } while (cleartext[count] != '\0');
    }
    ciphertext[count] = '\0';
}


int main()
{
    srand(time(NULL));
    char cleartext[MAX_SIZE], key[MAX_KEY_SIZE], ciphertext[MAX_SIZE];
    //ouverture du fichier et récupération du texte à encoder
    FILE *plaintextFile = fopen("plaintext.txt", "r");
    if (plaintextFile == NULL)
    {
        perror("Error opening plaintext.txt");
        return 1;
    }
    int cleartextSize = fread(cleartext, 1, MAX_SIZE, plaintextFile);
    fclose(plaintextFile);

    //ouverture du fichier et récupération de la clé pour encoder

    FILE *keyFile = fopen("key.txt", "r");
    if (keyFile == NULL)
    {
        perror("Error opening key.txt");
        return 1;
    }

    int keySize = fread(key, 1, MAX_SIZE, keyFile);
    fclose(keyFile);

    cleartext[cleartextSize] = '\0';
    key[keySize] = '\0';

    float t1 = clock();

    cipher(cleartext, key, ciphertext);

    float t2 = clock();

    float temps = ((float)(t2-t1)/CLOCKS_PER_SEC);
    printf("temps = %f\n", temps);

    FILE *ciphertextFile = fopen("ciphertext.txt", "w");
    if (ciphertextFile == NULL) {
        perror("Error opening ciphertext.txt for writing");
        return 1;
    }

    fwrite(ciphertext, 1, strlen(ciphertext), ciphertextFile);

    fclose(ciphertextFile);

    return 0;
}