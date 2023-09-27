
// Функция выполняет выгрузку списка пользователей информационной базы в файл.
// Для выгрузки используется схема, расположенная в макете обработки XMLСхема.
//
// Возвращаемое значение:
//   Структура		- Структура. Результат выгрузки.
//		Статус		- Булево. Собственно результат выгрузки: Истина - удачное завершение.
//		Количество	- Число. Количество выгруженных пользователей.
//		Адрес		- Строка. Адрес временного хранилища, по которому расположен файл с данными.
Функция ВыгрузитьПользователей() Экспорт
	
	РежимыЗапуска = Новый Соответствие;
	РежимыЗапуска.Вставить(РежимЗапускаКлиентскогоПриложения.Авто, "Auto");
	РежимыЗапуска.Вставить(РежимЗапускаКлиентскогоПриложения.ОбычноеПриложение, "OrdinaryApplication");
	РежимыЗапуска.Вставить(РежимЗапускаКлиентскогоПриложения.УправляемоеПриложение, "ManagedApplication");
	
	Результат = Новый Структура("Статус, Количество, Адрес", Ложь, 0, "");
	ИмяФайла = ПолучитьИмяВременногоФайла();
	Фабрика = СоздатьФабрику();
	Сериализатор = Новый СериализаторXDTO(Фабрика);
	
	ТипРоль = Фабрика.Тип(ИмяПространстваИмен(), "Role");
	ТипПользователь = Фабрика.Тип(ИмяПространстваИмен(), "User");
	
	Запись = Новый ЗаписьXML;
	Запись.ОткрытьФайл(ИмяФайла);
	Запись.ЗаписатьОбъявлениеXML();
	Запись.ЗаписатьНачалоЭлемента("users", ИмяПространстваИмен());
	Запись.ЗаписатьСоответствиеПространстваИмен("xs", "http://www.w3.org/2001/XMLSchema");
	Запись.ЗаписатьСоответствиеПространстваИмен("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	Запись.ЗаписатьСоответствиеПространстваИмен("usr", ИмяПространстваИмен());
	
	СписокПользователей = ПользователиИнформационнойБазы.ПолучитьПользователей();
	Для каждого Пользователь Из СписокПользователей Цикл
		User = Фабрика.Создать(ТипПользователь);
		User.OSAuthentication = Пользователь.АутентификацияОС;
		User.StandardAuthentication = Пользователь.АутентификацияСтандартная;
		User.OpenIDAuthentication = Пользователь.АутентификацияOpenID;
		User.CannotChangePassword = Пользователь.ЗапрещеноИзменятьПароль;
		User.Name = Пользователь.Имя;
		Если Пользователь.ОсновнойИнтерфейс <> Неопределено Тогда
			User.DefaultInterface = Пользователь.ОсновнойИнтерфейс.Имя;
		КонецЕсли;
		User.ShowInList = Пользователь.ПоказыватьВСпискеВыбора;
		User.FullName = Пользователь.ПолноеИмя;
		User.OSUser = Пользователь.ПользовательОС;
		User.RunMode = РежимыЗапуска[Пользователь.РежимЗапуска];
		User.StoredPasswordValue = Пользователь.СохраняемоеЗначениеПароля;
		User.UUID = Пользователь.УникальныйИдентификатор;
		Если Пользователь.Язык <> Неопределено Тогда
			User.Language = Пользователь.Язык.Имя;
		КонецЕсли;
		Для каждого Роль Из Пользователь.Роли Цикл
			Role = Фабрика.Создать(ТипРоль);
			Role.Name = Роль.Имя;
			User.Roles.Добавить(Role);
		КонецЦикла;
		Фабрика.ЗаписатьXML(Запись, User);
		Результат.Количество = Результат.Количество + 1;
	КонецЦикла;
	Запись.ЗаписатьКонецЭлемента();
	Запись.Закрыть();
	Данные = Новый ДвоичныеДанные(ИмяФайла);
	Результат.Адрес = ПоместитьВоВременноеХранилище(Данные);
	Результат.Статус = Истина;
	УдалитьФайлы(ИмяФайла);
	
	Возврат Результат;
	
КонецФункции

// Функция выполняет загрузку списка пользователей информационной базы из файла.
// Для загрузки используется схема, расположенная в макете обработки XMLСхема.
//
// Параметры
//  Адрес				- Строка. Адрес во временном хранилище, по которому расположен
//						загружаемый файл.
//  ПриоритетФайла		- Булево. Признак того, что нужно обновлять (Истина) данные пользователя
//						информационной базы данными из файла в случае совпадения имен.
//  ФормироватьПротокол	- Булево. Признак необходимости (Истина) формирования протокола загрузки.
//
// Возвращаемое значение:
//   Структура			- Структура. Результат загрузки.
//		Статус			- Булево. Собственно результат выгрузки: Истина - удачное завершение.
//		ИзФайла			- Число. Количество пользователей в файле с данными.
//		Загружено		- Число. Количество загруженных пользователей (в том числе совпадения).
//		Совпадений		- Число. Количество совпадений между информаицонной базой и файлом.
//		ФайлПротокола	- Строка. Адрес временного хранилища, по которому расположен файл с
//						протоколом (формируется только в случае, если ФормироватьПротокол = Истина).
Функция ЗагрузитьПользователей(Адрес, ПриоритетФайла, ФормироватьПротокол) Экспорт
	
	Результат = Новый Структура("Статус, ИзФайла, Загружено, Совпадений, ФайлПротокола", Ложь, 0, 0, 0, "");
	
	РежимыЗапуска = Новый Соответствие;
	РежимыЗапуска.Вставить("Auto", РежимЗапускаКлиентскогоПриложения.Авто);
	РежимыЗапуска.Вставить("OrdinaryApplication", РежимЗапускаКлиентскогоПриложения.ОбычноеПриложение);
	РежимыЗапуска.Вставить("ManagedApplication", РежимЗапускаКлиентскогоПриложения.УправляемоеПриложение);

	ИмяФайла = ПолучитьИмяВременногоФайла();
	Данные = ПолучитьИзВременногоХранилища(Адрес);
	Данные.Записать(ИмяФайла);
	
	Фабрика = СоздатьФабрику();
	Сериализатор = Новый СериализаторXDTO(Фабрика);
	ТипРоль = Фабрика.Тип(ИмяПространстваИмен(), "Role");
	ТипПользователь = Фабрика.Тип(ИмяПространстваИмен(), "User");
	
	Чтение = Новый ЧтениеXML;
	Чтение.ОткрытьФайл(ИмяФайла);
	Чтение.Прочитать();
	Чтение.ПерейтиКСодержимому();
	
	Если ФормироватьПротокол Тогда
		ИмяПротокола = ПолучитьИмяВременногоФайла("log");
		Протокол = Новый ЗаписьТекста(ИмяПротокола, КодировкаТекста.UTF8);
		ЗаписатьЭлементПротокола(Протокол, NStr("ru = 'Приоритет данных из файла:'", "ru") + " " + Строка(ПриоритетФайла));
	КонецЕсли;
	
	Если НЕ(Чтение.ТипУзла = ТипУзлаXML.НачалоЭлемента И Чтение.ЛокальноеИмя = "users") Тогда
		ЗаписатьЭлементПротокола(Протокол, NStr("ru = 'ОШИБКА: Неверный формат файла. Отсутствует узел <users>.'", "ru"));
		Результат.ФайлПротокола = ЗакрытьФайлПротокола(Протокол, ИмяПротокола);
		Возврат Результат;
	КонецЕсли;
	Чтение.Прочитать();
	Чтение.ПерейтиКСодержимому();
	Пока Чтение.ТипУзла = ТипУзлаXML.НачалоЭлемента И Чтение.ЛокальноеИмя = "User" Цикл
		Попытка
			ПрочитанныйОбъект = Фабрика.ПрочитатьXML(Чтение, ТипПользователь);
			Результат.ИзФайла = Результат.ИзФайла + 1;
			ПользовательИБ = ПользователиИнформационнойБазы.НайтиПоИмени(ПрочитанныйОбъект.Name);
			Если ПользовательИБ <> Неопределено Тогда
				Результат.Совпадений = Результат.Совпадений + 1;
				Если НЕ ПриоритетФайла Тогда
					Если ФормироватьПротокол Тогда
						ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'Пользователь: %1. Не изменен.'", "ru"), "%1", ПрочитанныйОбъект.Name));
					КонецЕсли;
					Продолжить;
				КонецЕсли;
			КонецЕсли;
			
			Если ПользовательИБ = Неопределено Тогда
				Если ФормироватьПротокол Тогда
					ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'Пользователь: %1. Создан новый.'", "ru"), "%1", ПрочитанныйОбъект.Name));
				КонецЕсли;
				ПользовательИБ = ПользователиИнформационнойБазы.СоздатьПользователя();
			Иначе	
				Если ФормироватьПротокол Тогда
					ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'Пользователь: %1. Обновлен данными из файла.'", "ru"), "%1", ПрочитанныйОбъект.Name));
				КонецЕсли;
			КонецЕсли;
			
			ПользовательИБ.Имя = ПрочитанныйОбъект.Name;
			ПользовательИБ.ПолноеИмя = ПрочитанныйОбъект.FullName;
			ПользовательИБ.АутентификацияОС = ПрочитанныйОбъект.OSAuthentication;
			ПользовательИБ.АутентификацияOpenID = ПрочитанныйОбъект.OpenIDAuthentication;
			ПользовательИБ.АутентификацияСтандартная = ПрочитанныйОбъект.StandardAuthentication;
			ПользовательИБ.ЗапрещеноИзменятьПароль = ПрочитанныйОбъект.CannotChangePassword;
			ПользовательИБ.ПоказыватьВСпискеВыбора = ПрочитанныйОбъект.ShowInList;
			ПользовательИБ.ПользовательОС = ПрочитанныйОбъект.OSUser;
			ПользовательИБ.СохраняемоеЗначениеПароля = ПрочитанныйОбъект.StoredPasswordValue;
			ПользовательИБ.РежимЗапуска = РежимыЗапуска[ПрочитанныйОбъект.RunMode];
			Если ПрочитанныйОбъект.Установлено("DefaultInterface") Тогда
				ИзФайла = ПрочитанныйОбъект.DefaultInterface;
				Если Метаданные.Интерфейсы.Найти(ИзФайла) = Неопределено Тогда
					Если ФормироватьПротокол Тогда
						ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'ОШИБКА: Интерфейс '%1' не обнаружен в информационной базе. Загрузка прервана.'", "ru"), "%1", ИзФайла));
					КонецЕсли;
					ВызватьИсключение "Ошибка";
				КонецЕсли;
				ПользовательИБ.ОсновнойИнтерфейс = Метаданные.Интерфейсы[ИзФайла];
			КонецЕсли;
			Если ПрочитанныйОбъект.Установлено("Language") Тогда
				ИзФайла = ПрочитанныйОбъект.Language;
				Если Метаданные.Языки.Найти(ИзФайла) = Неопределено Тогда
					Если ФормироватьПротокол Тогда
						ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'ОШИБКА: Язык '%1' не обнаружен в информационной базе. Загрузка прервана.'", "ru"), "%1", ИзФайла));
					КонецЕсли;
					ВызватьИсключение "Ошибка";
				КонецЕсли;
				ПользовательИБ.Язык = Метаданные.Языки[ИзФайла];
			КонецЕсли;
			Для каждого РольXDTO Из ПрочитанныйОбъект.Roles Цикл
				ИзФайла = РольXDTO.Name;
				Если Метаданные.Роли.Найти(ИзФайла) = Неопределено Тогда
					Если ФормироватьПротокол Тогда
						ЗаписатьЭлементПротокола(Протокол, СтрЗаменить(NStr("ru = 'ОШИБКА: Роль '%1' не обнаружена в информационной базе. Загрузка прервана.'", "ru"), "%1", ИзФайла));
					КонецЕсли;
					ВызватьИсключение "Ошибка";
				КонецЕсли;
				ПользовательИБ.Роли.Добавить(Метаданные.Роли[ИзФайла]);
			КонецЦикла;
			ПользовательИБ.Записать();
			Результат.Загружено = Результат.Загружено + 1;
		Исключение
			Если ФормироватьПротокол Тогда
				Результат.ФайлПротокола = ЗакрытьФайлПротокола(Протокол, ИмяПротокола);
			КонецЕсли;
			Чтение.Закрыть();
			УдалитьФайлы(ИмяФайла);
			Возврат Результат;
		КонецПопытки;
	КонецЦикла;
	
	Если ФормироватьПротокол Тогда
		Текст = НСтр("ru = 'Загрузка пользователей завершена. Всего прочитано: %1. Загружено: %2. Совпадений: %3.'", "ru");
		Текст = СтрЗаменить(Текст, "%1", Результат.ИзФайла);
		Текст = СтрЗаменить(Текст, "%2", Результат.Загружено);
		Текст = СтрЗаменить(Текст, "%3", Результат.Совпадений);
		ЗаписатьЭлементПротокола(Протокол, Текст);
		Результат.ФайлПротокола = ЗакрытьФайлПротокола(Протокол, ИмяПротокола);
	КонецЕсли;
	
	Чтение.Закрыть();
	УдалитьФайлы(ИмяФайла);
	Результат.Статус = Истина;
	
	Возврат Результат;
	
КонецФункции

Функция ИмяПространстваИмен()
	
	Возврат "http://v8.1c.ru/8.2/infobase/users-exchange";
	
КонецФункции

Функция СоздатьФабрику()
	
	Макет = ЭтотОбъект.ПолучитьМакет("XMLСхема");
	
	Чтение = Новый ЧтениеXML;
	Чтение.УстановитьСтроку(Макет.ПолучитьТекст());
	
	Построитель = Новый ПостроительDOM;
	Документ = Построитель.Прочитать(Чтение);
	
	ПостроительСхем = Новый ПостроительСхемXML;
	Схема = ПостроительСхем.СоздатьСхемуXML(Документ);
	
	НаборСхем = Новый НаборСхемXML;
	НаборСхем.Добавить(Схема);
	
	Возврат Новый ФабрикаXDTO(НаборСхем);
	
КонецФункции

Процедура ЗаписатьЭлементПротокола(ФайлПротокола, ТекстДляПротокола)
	
	ФайлПротокола.ЗаписатьСтроку(ТекстДляПротокола);
	
КонецПроцедуры

Функция ЗакрытьФайлПротокола(ФайлПротокола, ИмяФайла)
	
	ФайлПротокола.Закрыть();
	Данные = Новый ДвоичныеДанные(ИмяФайла);
	Результат = ПоместитьВоВременноеХранилище(Данные);
	УдалитьФайлы(ИмяФайла);
	
	Возврат Результат;
	
КонецФункции
